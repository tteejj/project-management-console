# ===============================================================================
# PMC (Project Management Console) - Complete Module Bundle
# Generated: 2025-09-25 05:28:42
#
# This file contains the complete PMC module concatenated into a single file
# for easy transport and deployment.
#
# Original structure:
# - Module manifest (.psd1)
# - Main module file (.psm1)
# - 70 PowerShell source files
#
# To use this file:
# 1. Extract individual files or
# 2. Load sections as needed or
# 3. Use as reference for the complete codebase
# ===============================================================================


# ================================================================================
# FILE: ./module/Pmc.Strict/Pmc.Strict.psd1
# SIZE: 6.14 KB
# MODIFIED: 2025-09-23 21:17:11
# ================================================================================

@{
    RootModule        = 'Pmc.Strict.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '5b2d6a0a-8a8f-4e2a-9d0d-3a3b0e2a3b6f'
    Author            = 'pmc'
    CompanyName       = 'pmc'
    Copyright         = '(c) pmc'
    Description       = 'Strict, homogeneous domain-action command engine for pmc.'
    PowerShellVersion = '5.1'
    TypesToProcess    = @()
    FunctionsToExport = @(
        'Invoke-PmcCommand',
        'Get-PmcSchema',
        'Get-PmcHelp',
        'Get-PmcHelpData',
        'Show-PmcHelpUI',
        'Show-PmcHelpDomain',
        'Show-PmcHelpCommand',
        'Show-PmcHelpQuery',
        'Show-PmcHelpAll',
        'Start-PmcProjectWizard',
        'Set-PmcConfigProvider',
        'Enable-PmcInteractiveMode',
        'Disable-PmcInteractiveMode',
        'Get-PmcInteractiveStatus',
        'Read-PmcCommand',
        'Write-PmcDebug',
        'Get-PmcDebugStatus',
        'Show-PmcDebugLog',
        'Measure-PmcOperation',
        'Initialize-PmcDebugSystem',
        'Initialize-PmcSecuritySystem',
        'Initialize-PmcThemeSystem',
        'Update-PmcDebugFromConfig',
        'Update-PmcSecurityFromConfig',
        'Get-PmcConfig',
        'Get-PmcConfigProviders',
        'Set-PmcConfigProviders',
        'Get-PmcState',
        'Set-PmcState',
        'ConvertTo-PmcTokens',
        'ConvertTo-PmcDate',
        'Show-PmcSmartHelp',
        'Write-PmcStyled',
        'Get-PmcStyle',
        'Test-PmcInputSafety',
        'Test-PmcPathSafety',
        'Invoke-PmcSecureFileOperation',
        'Protect-PmcUserInput',
        'Get-PmcSecurityStatus',
        'Set-PmcSecurityLevel',
        # TASK DOMAIN HANDLERS
        'Add-PmcTask',
        'Get-PmcTaskList',
        'Show-PmcTask',
        'Set-PmcTask',
        'Complete-PmcTask',
        'Remove-PmcTask',
        'Move-PmcTask',
        'Set-PmcTaskPostponed',
        'Copy-PmcTask',
        'Add-PmcTaskNote',
        'Edit-PmcTask',
        'Find-PmcTask',
        'Set-PmcTaskPriority',
        'Show-PmcAgenda',
        'Show-PmcWeekTasks',
        'Show-PmcMonthTasks',
        # PROJECT DOMAIN HANDLERS
        'Add-PmcProject',
        'Get-PmcProjectList',
        'Show-PmcProject',
        'Set-PmcProject',
        'Rename-PmcProject',
        'Remove-PmcProject',
        'Set-PmcProjectArchived',
        'Set-PmcProjectFields',
        'Show-PmcProjectFields',
        'Get-PmcProjectStats',
        'Show-PmcProjectInfo',
        'Get-PmcRecentProjects',
        # TIME/TIMER DOMAIN HANDLERS
        'Add-PmcTimeEntry',
        'Get-PmcTimeReport',
        'Get-PmcTimeList',
        'Edit-PmcTimeEntry',
        'Remove-PmcTimeEntry',
        'Start-PmcTimer',
        'Stop-PmcTimer',
        'Get-PmcTimerStatus',
        # ACTIVITY DOMAIN
        'Get-PmcActivityList',
        # TEMPLATE DOMAIN
        'Save-PmcTemplate',
        'Invoke-PmcTemplate',
        'Get-PmcTemplateList',
        'Remove-PmcTemplate',
        # RECURRING DOMAIN
        'Add-PmcRecurringTask',
        # ALIAS DOMAIN
        'Add-PmcAlias',
        'Remove-PmcAlias',
        # DEPENDENCY DOMAIN
        'Add-PmcDependency',
        'Remove-PmcDependency',
        'Show-PmcDependencies',
        'Show-PmcDependencyGraph',
        # FOCUS DOMAIN
        'Set-PmcFocus',
        'Clear-PmcFocus',
        'Get-PmcFocusStatus',
        # SYSTEM DOMAIN
        'Invoke-PmcUndo',
        'Invoke-PmcRedo',
        'New-PmcBackup',
        'Clear-PmcCompletedTasks',
        # VIEW DOMAIN
        'Show-PmcTodayTasks',
        'Show-PmcTomorrowTasks',
        'Show-PmcOverdueTasks',
        'Show-PmcUpcomingTasks',
        'Show-PmcBlockedTasks',
        'Show-PmcNoDueDateTasks',
        'Show-PmcProjectsView',
        'Show-PmcNextTasks',
        # EXCEL DOMAIN
        'Import-PmcExcelData',
        'Show-PmcExcelPreview',
        'Get-PmcLatestExcelFile',
        # THEME DOMAIN
        'Reset-PmcTheme',
        'Edit-PmcTheme',
        'Get-PmcThemeList',
        'Apply-PmcTheme',
        'Show-PmcThemeInfo',
        # CONFIG DOMAIN
        'Show-PmcConfig',
        'Edit-PmcConfig',
        'Set-PmcConfigValue',
        'Reload-PmcConfig',
        'Validate-PmcConfig',
        'Set-PmcIconMode',
        # IMPORT/EXPORT DOMAIN
        'Import-PmcTasks',
        'Export-PmcTasks',
        # SHOW DOMAIN
        'Get-PmcAliasList',
        'Show-PmcCommands',
        # HELP DOMAIN
        'Show-PmcCommandBrowser',
        'Show-PmcHelpExamples',
        'Show-PmcHelpGuide',
        # SHORTCUT-ONLY FUNCTIONS
        'Get-PmcStats',
        'Show-PmcBurndown',
        'Get-PmcVelocity',
        'Set-PmcTheme',
        'Show-PmcPreferences',
        'Invoke-PmcShortcutNumber',
        'Start-PmcReview',
        # XFLOW (Excel flow lite)
        'Set-PmcXFlowSourcePathInteractive',
        'Set-PmcXFlowDestPathInteractive',
        'Show-PmcXFlowPreview',
        'Invoke-PmcXFlowRun',
        'Export-PmcXFlowText',
        'Import-PmcXFlowMappingsFromFile',
        'Set-PmcXFlowLatestFromFile',
        'Show-PmcXFlowConfig',
        # DATA DISPLAY SYSTEM
        'Show-PmcDataGrid',
        # UNIVERSAL DISPLAY SYSTEM
        'Show-PmcData',
        'Get-PmcDefaultColumns',
        'Register-PmcUniversalCommands',
        'Get-PmcUniversalCommands',
        'Ensure-PmcUniversalDisplay',
        # Interactive view entrypoints
        'Show-PmcTodayTasksInteractive',
        'Show-PmcOverdueTasksInteractive',
        'Show-PmcAgendaInteractive',
        'Show-PmcProjectsInteractive',
        'Show-PmcAllTasksInteractive',
        # QUERY DOMAIN
        'Invoke-PmcQuery',
        'Evaluate-PmcQuery',
        'Get-PmcComputedRegistry',
        'Get-PmcQueryAlias',
        'Set-PmcQueryAlias',
        'Show-PmcCustomGrid',
        # SCREEN MANAGEMENT SYSTEM
        'Initialize-PmcScreen',
        'Clear-PmcContentArea',
        'Get-PmcContentBounds',
        'Set-PmcHeader',
        'Set-PmcInputPrompt',
        'Hide-PmcCursor',
        'Show-PmcCursor',
        'Reset-PmcScreen',
        'Write-PmcAtPosition',
        # DATA ACCESS
        'Get-PmcAllData',
        'Get-PmcDataProvider'
    )
    AliasesToExport   = @()
    CmdletsToExport   = @()
    VariablesToExport = @('PmcCommandMap', 'PmcShortcutMap', 'PmcCommandMeta')
}


# END FILE: ./module/Pmc.Strict/Pmc.Strict.psd1


# ================================================================================
# FILE: ./module/Pmc.Strict/Pmc.Strict.psm1
# SIZE: 22.49 KB
# MODIFIED: 2025-09-24 05:04:00
# ================================================================================

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

# Template specification and renderer - moved to module scope for proper class export
class PmcTemplate {
    [string]$Name
    [string]$Type        # 'grid', 'list', 'card', 'summary'
    [string]$Header      # Header template
    [string]$Row         # Row/item template
    [string]$Footer      # Footer template
    [hashtable]$Settings # Width, alignment, etc.

    PmcTemplate([string]$name, [hashtable]$config) {
        $this.Name = $name
        $this.Type = if ($config.ContainsKey('type')) { $config.type } else { 'list' }
        $this.Header = if ($config.ContainsKey('header')) { $config.header } else { '' }
        $this.Row = if ($config.ContainsKey('row')) { $config.row } else { '' }
        $this.Footer = if ($config.ContainsKey('footer')) { $config.footer } else { '' }
        $this.Settings = if ($config.ContainsKey('settings')) { $config.settings } else { @{} }
    }
}

# Dot-source internal components with debug tracing
# Module loading in progress...

try {
    # Loading Types.ps1...
    . $PSScriptRoot/src/Types.ps1
    # ✓ Types.ps1 loaded
} catch {
    Write-Host "✗ PMC module loading failed: Types.ps1 - $_" -ForegroundColor Red
    throw
}

# Load terminal dimension service early as many modules depend on it
try {
    # Loading TerminalDimensions.ps1...
    . $PSScriptRoot/src/TerminalDimensions.ps1
    # ✓ TerminalDimensions.ps1 loaded
} catch {
    Write-Host "✗ PMC module loading failed: TerminalDimensions.ps1 - $_" -ForegroundColor Red
    throw
}

# Ensure centralized state is available before any consumer
try {
    # Loading State.ps1...
    . $PSScriptRoot/src/State.ps1
    # ✓ State.ps1 loaded
} catch {
    Write-Host "✗ PMC module loading failed: State.ps1 - $_" -ForegroundColor Red
    throw
}

# Config providers and helpers before Debug/Security which consult config
try {
    # Loading Config.ps1...
    . $PSScriptRoot/src/Config.ps1
    # ✓ Config.ps1 loaded
} catch {
    Write-Host "✗ PMC module loading failed: Config.ps1 - $_" -ForegroundColor Red
    throw
}

# Now load Debug and Security modules (no auto-init inside files)
try {
    # Loading Debug.ps1...
    . $PSScriptRoot/src/Debug.ps1
    # ✓ Debug.ps1 loaded
} catch {
    Write-Host "  ✗ Debug.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading Security.ps1...
    . $PSScriptRoot/src/Security.ps1
    # ✓ Security.ps1 loaded
} catch {
    Write-Host "  ✗ Security.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading Storage.ps1...
    . $PSScriptRoot/src/Storage.ps1
    # ✓ Storage.ps1 loaded
} catch {
    Write-Host "  ✗ Storage.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading UI.ps1...
    . $PSScriptRoot/src/UI.ps1
    # ✓ UI.ps1 loaded
} catch {
    Write-Host "  ✗ UI.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading ScreenManager.ps1...
    . $PSScriptRoot/src/ScreenManager.ps1
    # ✓ ScreenManager.ps1 loaded
} catch {
    Write-Host "  ✗ ScreenManager.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading Resolvers.ps1...
    . $PSScriptRoot/src/Resolvers.ps1
    # ✓ Resolvers.ps1 loaded
} catch {
    Write-Host "  ✗ Resolvers.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading CommandMap.ps1...
    . $PSScriptRoot/src/CommandMap.ps1
    # ✓ CommandMap.ps1 loaded
} catch {
    Write-Host "  ✗ CommandMap.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading Schemas.ps1...
    . $PSScriptRoot/src/Schemas.ps1
    # ✓ Schemas.ps1 loaded
} catch {
    Write-Host "  ✗ Schemas.ps1 failed: $_" -ForegroundColor Red
    throw
}

## moved earlier

try {
    # Loading AstCommandParser.ps1...
    . $PSScriptRoot/src/AstCommandParser.ps1
    # ✓ AstCommandParser.ps1 loaded
} catch {
    Write-Host "  ✗ AstCommandParser.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading AstCompletion.ps1...
    . $PSScriptRoot/src/AstCompletion.ps1
    # ✓ AstCompletion.ps1 loaded
} catch {
    Write-Host "  ✗ AstCompletion.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading TemplateDisplay.ps1...
    . $PSScriptRoot/src/TemplateDisplay.ps1
    # ✓ TemplateDisplay.ps1 loaded
} catch {
    Write-Host "  ✗ TemplateDisplay.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading Execution.ps1...
    . $PSScriptRoot/src/Execution.ps1
    # ✓ Execution.ps1 loaded
} catch {
    Write-Host "  ✗ Execution.ps1 failed: $_" -ForegroundColor Red
    throw
}


try {
    # Loading Help.ps1...
    . $PSScriptRoot/src/Help.ps1
    # ✓ Help.ps1 loaded
} catch {
    Write-Host "  ✗ Help.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading Interactive.ps1...
    . $PSScriptRoot/src/Interactive.ps1
    # ✓ Interactive.ps1 loaded
} catch {
    Write-Host "  ✗ Interactive.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading Dependencies.ps1...
    . $PSScriptRoot/src/Dependencies.ps1
    # ✓ Dependencies.ps1 loaded
} catch {
    Write-Host "  ✗ Dependencies.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading Focus.ps1...
    . $PSScriptRoot/src/Focus.ps1
    # ✓ Focus.ps1 loaded
} catch {
    Write-Host "  ✗ Focus.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading Time.ps1...
    . $PSScriptRoot/src/Time.ps1
    # ✓ Time.ps1 loaded
} catch {
    Write-Host "  ✗ Time.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading UndoRedo.ps1...
    . $PSScriptRoot/src/UndoRedo.ps1
    # ✓ UndoRedo.ps1 loaded
} catch {
    Write-Host "  ✗ UndoRedo.ps1 failed: $_" -ForegroundColor Red
    throw
}

# Views.ps1 functionality migrated to UniversalDisplay.ps1 during technical debt cleanup

try {
    # Loading Aliases.ps1...
    . $PSScriptRoot/src/Aliases.ps1
    # ✓ Aliases.ps1 loaded
} catch {
    Write-Host "  ✗ Aliases.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading Analytics.ps1...
    . $PSScriptRoot/src/Analytics.ps1
    # ✓ Analytics.ps1 loaded
} catch {
    Write-Host "  ✗ Analytics.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading Theme.ps1...
    . $PSScriptRoot/src/Theme.ps1
    # ✓ Theme.ps1 loaded
} catch {
    Write-Host "  ✗ Theme.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading Excel.ps1...
    . $PSScriptRoot/src/Excel.ps1
    # ✓ Excel.ps1 loaded
} catch {
    Write-Host "  ✗ Excel.ps1 failed: $_" -ForegroundColor Red
    throw
}

# Excel Flow Lite (interactive path pickers for source/dest)
try {
    # Loading ExcelFlowLite.ps1...
    . $PSScriptRoot/src/ExcelFlowLite.ps1
    # ✓ ExcelFlowLite.ps1 loaded
} catch {
    Write-Host "  ✗ ExcelFlowLite.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading ImportExport.ps1...
    . $PSScriptRoot/src/ImportExport.ps1
    # ✓ ImportExport.ps1 loaded
} catch {
    Write-Host "  ✗ ImportExport.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading Shortcuts.ps1...
    . $PSScriptRoot/src/Shortcuts.ps1
    # ✓ Shortcuts.ps1 loaded
} catch {
    Write-Host "  ✗ Shortcuts.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading Review.ps1...
    . $PSScriptRoot/src/Review.ps1
    # ✓ Review.ps1 loaded
} catch {
    Write-Host "  ✗ Review.ps1 failed: $_" -ForegroundColor Red
    throw
}

# Initialize help content data structure - organized from reference doc
$Script:PmcHelpContent = @{
    'Query Language' = @{
        Description = 'Filter, sort, and display tasks, projects, and time logs'
        Items = @(
            @{ Type='Basic'; Command='q tasks'; Description='Show all tasks' }
            @{ Type='Filter'; Command='q tasks p1'; Description='High priority tasks' }
            @{ Type='Filter'; Command='q tasks due:today'; Description='Tasks due today' }
            @{ Type='Filter'; Command='q tasks @webapp'; Description='Tasks for webapp project' }
            @{ Type='Filter'; Command='q tasks #urgent'; Description='Tasks tagged urgent' }
            @{ Type='Filter'; Command='q tasks overdue'; Description='Overdue tasks' }
            @{ Type='Filter'; Command='q tasks "database"'; Description='Text search for "database"' }
            @{ Type='View'; Command='q tasks group:status'; Description='Kanban board by status' }
            @{ Type='View'; Command='q tasks cols:id,text,due'; Description='Custom columns' }
            @{ Type='View'; Command='q tasks sort:due+'; Description='Sort by due date ascending' }
            @{ Type='Combo'; Command='q tasks @webapp p<=2 due:+7'; Description='Multiple filters combined' }
            @{ Type='Save'; Command='q tasks p1 due:today save:urgent'; Description='Save query as "urgent"' }
            @{ Type='Load'; Command='q load:urgent'; Description='Load saved query' }
        )
    }
    'Priority Filters' = @{
        Description = 'Filter tasks by priority level'
        Items = @(
            @{ Type='Basic'; Command='q tasks p1'; Description='Priority 1 (highest)' }
            @{ Type='Basic'; Command='q tasks p2'; Description='Priority 2 (medium)' }
            @{ Type='Basic'; Command='q tasks p3'; Description='Priority 3 (lowest)' }
            @{ Type='Range'; Command='q tasks p<=2'; Description='Priority 2 or higher' }
            @{ Type='Range'; Command='q tasks p1..3'; Description='Priority range 1 to 3' }
        )
    }
    'Date Filters' = @{
        Description = 'Filter tasks by dates and deadlines'
        Items = @(
            @{ Type='Relative'; Command='q tasks due:today'; Description='Due today' }
            @{ Type='Relative'; Command='q tasks due:tomorrow'; Description='Due tomorrow' }
            @{ Type='Relative'; Command='q tasks due:+7'; Description='Due in 7 days' }
            @{ Type='Relative'; Command='q tasks due:eow'; Description='Due end of week (Sunday)' }
            @{ Type='Relative'; Command='q tasks due:eom'; Description='Due end of month' }
            @{ Type='Relative'; Command='q tasks due:1m'; Description='Due in 1 month' }
            @{ Type='Absolute'; Command='q tasks due:20251225'; Description='Due Dec 25, 2025 (yyyymmdd)' }
            @{ Type='Absolute'; Command='q tasks due:1225'; Description='Due Dec 25 (current year)' }
            @{ Type='Status'; Command='q tasks overdue'; Description='Overdue tasks' }
        )
    }
    'Project Filters' = @{
        Description = 'Filter by project names and assignments'
        Items = @(
            @{ Type='Basic'; Command='q tasks @webapp'; Description='Tasks for project "webapp"' }
            @{ Type='Quoted'; Command='q tasks @"project name"'; Description='Projects with spaces' }
            @{ Type='Multiple'; Command='q tasks @webapp @api'; Description='Tasks from multiple projects' }
            @{ Type='Negative'; Command='q tasks -@archived'; Description='Exclude archived project' }
        )
    }
    'Tag Filters' = @{
        Description = 'Filter by tags and labels'
        Items = @(
            @{ Type='Basic'; Command='q tasks #urgent'; Description='Has "urgent" tag' }
            @{ Type='Multiple'; Command='q tasks #web #api'; Description='Has both "web" and "api" tags' }
            @{ Type='Negative'; Command='q tasks -#blocked'; Description='Does NOT have "blocked" tag' }
        )
    }
    'Display Options' = @{
        Description = 'Control how results are displayed'
        Items = @(
            @{ Type='Columns'; Command='q tasks cols:id,text,due'; Description='Show only specified columns' }
            @{ Type='Columns'; Command='q tasks cols:id,text,due,priority'; Description='Include priority column' }
            @{ Type='Sort'; Command='q tasks sort:due+'; Description='Sort by due date ascending' }
            @{ Type='Sort'; Command='q tasks sort:priority-'; Description='Sort by priority descending' }
            @{ Type='Sort'; Command='q tasks sort:due+,priority-'; Description='Multi-column sort' }
            @{ Type='View'; Command='q tasks view:kanban'; Description='Display as Kanban board' }
            @{ Type='View'; Command='q tasks view:list'; Description='Display as list (default)' }
            @{ Type='Group'; Command='q tasks group:status'; Description='Group by status' }
            @{ Type='Group'; Command='q tasks group:project'; Description='Group by project' }
        )
    }
    'Advanced Features' = @{
        Description = 'Metrics, relations, and saved queries'
        Items = @(
            @{ Type='Metrics'; Command='q tasks metrics:time_week'; Description='Add time logged this week' }
            @{ Type='Metrics'; Command='q tasks metrics:time_today'; Description='Add time logged today' }
            @{ Type='Metrics'; Command='q tasks metrics:overdue_days'; Description='Add days overdue' }
            @{ Type='Relations'; Command='q tasks with:project'; Description='Include related project data' }
            @{ Type='Relations'; Command='q projects with:tasks'; Description='Include related tasks' }
            @{ Type='Save'; Command='q tasks p1 due:today save:myquery'; Description='Save query as "myquery"' }
            @{ Type='Load'; Command='q load:myquery'; Description='Load saved query' }
        )
    }
    'Quick Tasks' = @{
        Description = 'Common task management commands'
        Items = @(
            @{ Type='View'; Command='today'; Description='Tasks due today' }
            @{ Type='View'; Command='overdue'; Description='Overdue tasks' }
            @{ Type='View'; Command='agenda'; Description='Agenda view' }
            @{ Type='Add'; Command='add "Task text" @project p1 due:today'; Description='Add new task' }
            @{ Type='Edit'; Command='edit 123'; Description='Edit task by ID' }
            @{ Type='Complete'; Command='done 123'; Description='Mark task complete' }
        )
    }
    'Projects' = @{
        Description = 'Project management commands'
        Items = @(
            @{ Type='View'; Command='projects'; Description='List all projects' }
            @{ Type='Add'; Command='project add "Project Name"'; Description='Create new project' }
            @{ Type='View'; Command='project show webapp'; Description='Show project details' }
            @{ Type='Edit'; Command='project edit webapp'; Description='Edit project settings' }
        )
    }
    'Time Tracking' = @{
        Description = 'Time logging and reports'
        Items = @(
            @{ Type='Start'; Command='timer start @project "Working on feature"'; Description='Start timer' }
            @{ Type='Stop'; Command='timer stop'; Description='Stop current timer' }
            @{ Type='Status'; Command='timer status'; Description='Show timer status' }
            @{ Type='Add'; Command='time add 2h @project "Meeting"'; Description='Log time manually' }
            @{ Type='Report'; Command='time report week'; Description='Weekly time report' }
        )
    }
}

# Help data provider function - needs to be in same scope as $Script:PmcHelpContent
function Get-PmcHelpData {
    param([PmcCommandContext]$Context)
    # Return help categories as domain data for universal display system
    $helpCategories = @()

    if ($Script:PmcHelpContent -and $Script:PmcHelpContent.Count -gt 0) {
        $id = 1
        foreach ($categoryEntry in $Script:PmcHelpContent.GetEnumerator()) {
            $helpCategories += [PSCustomObject]@{
                id = $id++
                Category = $categoryEntry.Key
                CommandCount = $categoryEntry.Value.Items.Count
                Description = $categoryEntry.Value.Description
            }
        }
    }

    return $helpCategories
}

try {
    # Loading HelpUI.ps1...
    . $PSScriptRoot/src/HelpUI.ps1
    # ✓ HelpUI.ps1 loaded
} catch {
    Write-Host "  ✗ HelpUI.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading TaskEditor.ps1...
    . $PSScriptRoot/src/TaskEditor.ps1
    # ✓ TaskEditor.ps1 loaded
} catch {
    Write-Host "  ✗ TaskEditor.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading ProjectWizard.ps1...
    . $PSScriptRoot/src/ProjectWizard.ps1
    # ✓ ProjectWizard.ps1 loaded
} catch {
    Write-Host "  ✗ ProjectWizard.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading Projects.ps1...
    . $PSScriptRoot/src/Projects.ps1
    # ✓ Projects.ps1 loaded
} catch {
    Write-Host "  ✗ Projects.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading Tasks.ps1...
    . $PSScriptRoot/src/Tasks.ps1
    # ✓ Tasks.ps1 loaded
} catch {
    Write-Host "  ✗ Tasks.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading Views.ps1...
    . $PSScriptRoot/src/Views.ps1
    # ✓ Views.ps1 loaded
} catch {
    Write-Host "  ✗ Views.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading PraxisVT.ps1...
    . $PSScriptRoot/src/PraxisVT.ps1
    # ✓ PraxisVT.ps1 loaded
} catch {
    Write-Host "  ✗ PraxisVT.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading PraxisStringBuilder.ps1...
    . $PSScriptRoot/src/PraxisStringBuilder.ps1
    # ✓ PraxisStringBuilder.ps1 loaded
} catch {
    Write-Host "  ✗ PraxisStringBuilder.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading FieldSchemas.ps1...
    . $PSScriptRoot/src/FieldSchemas.ps1
    # ✓ FieldSchemas.ps1 loaded
} catch {
    Write-Host "  ✗ FieldSchemas.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading QuerySpec.ps1...
    . $PSScriptRoot/src/QuerySpec.ps1
    # ✓ QuerySpec.ps1 loaded
} catch {
    Write-Host "  ✗ QuerySpec.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading Query.ps1...
    . $PSScriptRoot/src/Query.ps1
    # ✓ Query.ps1 loaded
} catch {
    Write-Host "  ✗ Query.ps1 failed: $_" -ForegroundColor Red
    throw
}

# Query engine dependencies (computed fields, evaluator, kanban renderer)
try {
    # Loading ComputedFields.ps1...
    . $PSScriptRoot/src/ComputedFields.ps1
    # ✓ ComputedFields.ps1 loaded
} catch {
    Write-Host "  ✗ ComputedFields.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading QueryEvaluator.ps1...
    . $PSScriptRoot/src/QueryEvaluator.ps1
    # ✓ QueryEvaluator.ps1 loaded
} catch {
    Write-Host "  ✗ QueryEvaluator.ps1 failed: $_" -ForegroundColor Red
    throw
}


try {
    # Loading PraxisFrameRenderer.ps1...
    . $PSScriptRoot/src/PraxisFrameRenderer.ps1
    # ✓ PraxisFrameRenderer.ps1 loaded
} catch {
    Write-Host "  ✗ PraxisFrameRenderer.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading DataDisplay.ps1...
    . $PSScriptRoot/src/DataDisplay.ps1
    # ✓ DataDisplay.ps1 loaded
} catch {
    Write-Host "  ✗ DataDisplay.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading KanbanRenderer.ps1...
    . $PSScriptRoot/src/KanbanRenderer.ps1
    # ✓ KanbanRenderer.ps1 loaded
} catch {
    Write-Host "  ✗ KanbanRenderer.ps1 failed: $_" -ForegroundColor Red
    throw
}

try {
    # Loading UniversalDisplay.ps1...
    . $PSScriptRoot/src/UniversalDisplay.ps1
    # ✓ UniversalDisplay.ps1 loaded
} catch {
    Write-Host "  ✗ UniversalDisplay.ps1 failed: $_" -ForegroundColor Red
    throw
}

 


# Clear screen after module loading completes
if (Get-Command Reset-PmcScreen -ErrorAction SilentlyContinue) {
    Reset-PmcScreen
}

Write-Host "✓ PMC loaded" -ForegroundColor Green

# Ensure required public functions are exported (override narrow exports in sub-files)
Export-ModuleMember -Function `
    Invoke-PmcCommand, `
    Get-PmcSchema, `
    Get-PmcFieldSchema, Get-PmcFieldSchemasForDomain, `
    Invoke-PmcQuery, `
    Get-PmcHelp, `
    Get-PmcHelpData, `
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
    Read-PmcCommand, `
    Show-PmcSmartHelp, `
    Show-PmcHelpDomain, `
    Show-PmcHelpCommand, `
    Show-PmcHelpUI, `
    Show-PmcCommandBrowser, `
    Show-PmcHelpExamples, `
    Show-PmcHelpGuide, `
    Show-PmcHelpSearch, `
    Invoke-PmcTaskEditor, `
    Show-PmcAgenda, `
    Show-PmcTodayTasks, `
    Show-PmcOverdueTasks, `
    Show-PmcUpcomingTasks, `
    Show-PmcBlockedTasks, `
    Show-PmcTasksWithoutDueDate, `
    Show-PmcProjectsView, `
    Get-PmcTaskList, `
    Get-PmcProjectList, `
    Show-PmcDataGrid, Show-PmcCustomGrid, `
    Show-PmcData, `
    Initialize-PmcScreen, `
    Clear-PmcContentArea, `
    Get-PmcContentBounds, `
    Set-PmcHeader, `
    Set-PmcInputPrompt, `
    Hide-PmcCursor, `
    Show-PmcCursor, `
    Reset-PmcScreen, `
    Write-PmcAtPosition

# Export variables explicitly
Export-ModuleMember -Variable PmcCommandMap, PmcShortcutMap, PmcCommandMeta

# Load Services directory for additional functionality
try {
    . $PSScriptRoot/Services/LegacyCompat.ps1
    Write-Host "✓ LegacyCompat services loaded" -ForegroundColor Green
} catch {
    Write-Host "✗ LegacyCompat services failed: $_" -ForegroundColor Red
}

# Register universal command shortcuts after export so functions are available
try {
    if (Get-Command Register-PmcUniversalCommands -ErrorAction SilentlyContinue) {
        Register-PmcUniversalCommands
        Write-Host "✓ Universal command shortcuts registered" -ForegroundColor Green
    } else {
        Write-Host "✗ Register-PmcUniversalCommands function not found" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Universal Display initialization failed: $_" -ForegroundColor Red
}

# Modules loaded after Export-ModuleMember removed to fix export issues


# END FILE: ./module/Pmc.Strict/Pmc.Strict.psm1


# ================================================================================
# FILE: ./module/Pmc.Strict/Core/DataProviders.ps1
# SIZE: 1.23 KB
# MODIFIED: 2025-09-21 16:36:53
# ================================================================================

# Core data providers for Unified UI (pure data, no UI writes)

Set-StrictMode -Version Latest

function Get-PmcTasksData {
    try {
        $root = Get-PmcDataAlias
        $items = @()
        if ($root -and $root.PSObject.Properties['tasks']) { $items = @($root.tasks) }
        return ,$items
    } catch {
        Write-PmcDebug -Level 1 -Category 'DataProviders' -Message ("Get-PmcTasksData failed: {0}" -f $_)
        return @()
    }
}

function Get-PmcProjectsData {
    try {
        $root = Get-PmcDataAlias
        $items = @()
        if ($root -and $root.PSObject.Properties['projects']) { $items = @($root.projects) }
        return ,$items
    } catch {
        Write-PmcDebug -Level 1 -Category 'DataProviders' -Message ("Get-PmcProjectsData failed: {0}" -f $_)
        return @()
    }
}

function Get-PmcTimeLogsData {
    try {
        $root = Get-PmcDataAlias
        $items = @()
        if ($root -and $root.PSObject.Properties['timelogs']) { $items = @($root.timelogs) }
        return ,$items
    } catch {
        Write-PmcDebug -Level 1 -Category 'DataProviders' -Message ("Get-PmcTimeLogsData failed: {0}" -f $_)
        return @()
    }
}

Export-ModuleMember -Function Get-PmcTasksData, Get-PmcProjectsData, Get-PmcTimeLogsData



# END FILE: ./module/Pmc.Strict/Core/DataProviders.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/Core/EnhancedCommandProcessor.ps1
# SIZE: 13.24 KB
# MODIFIED: 2025-09-21 18:33:38
# ================================================================================

# PMC Enhanced Command Processor - Secure, performant command execution
# Implements Phase 3 core logic improvements

Set-StrictMode -Version Latest

# Input sanitization and validation
class PmcInputSanitizer {
    static [string] SanitizeCommandInput([string]$input) {
        if (-not $input) { return "" }

        # Validate length
        if ($input.Length -gt 2000) {
            throw "Command input too long (max 2000 characters)"
        }

        # Remove dangerous characters that could enable injection
        $sanitized = $input -replace '[`$;&|<>{}]', ''

        # Check for potentially dangerous patterns
        $dangerousPatterns = @(
            'Invoke-Expression', 'iex', 'cmd\.exe', 'powershell\.exe',
            'Start-Process', 'New-Object.*System\.', 'Get-WmiObject',
            '\[.*\]::.*', 'Add-Type', 'Reflection\.'
        )

        foreach ($pattern in $dangerousPatterns) {
            if ($sanitized -match $pattern) {
                throw "Potentially dangerous input detected: $pattern"
            }
        }

        return $sanitized.Trim()
    }

    static [bool] ValidateTokenSafety([string]$token) {
        if (-not $token) { return $true }

        # Allow expected PMC patterns
        $safePatterns = @(
            '^@[\w\s\-\.]+$',      # Project references
            '^p[1-3]$',             # Priority
            '^due:[\w\-:]+$',       # Due dates
            '^#[\w\-]+$',           # Tags
            '^task:\d+$',           # Task references
            '^[\w\-\.\s]+$'         # General text
        )

        foreach ($pattern in $safePatterns) {
            if ($token -match $pattern) { return $true }
        }

        # Check length
        if ($token.Length -gt 100) { return $false }

        # Reject dangerous patterns
        if ($token -match '[`$;&|<>{}()[\]]') { return $false }

        return $true
    }
}

# Enhanced command context with validation
class PmcEnhancedCommandContext {
    [string] $Domain
    [string] $Action
    [hashtable] $Args = @{}
    [string[]] $FreeText = @()
    [datetime] $Timestamp = [datetime]::Now
    [string] $OriginalInput
    [hashtable] $Metadata = @{}
    [bool] $IsValidated = $false
    [string[]] $ValidationErrors = @()

    PmcEnhancedCommandContext([string]$domain, [string]$action) {
        $this.Domain = $domain
        $this.Action = $action
    }

    [void] AddValidationError([string]$error) {
        $this.ValidationErrors += $error
    }

    [bool] IsValid() {
        return $this.ValidationErrors.Count -eq 0
    }

    [void] MarkValidated() {
        $this.IsValidated = $true
    }
}

# Performance monitoring for command execution
class PmcCommandPerformanceMonitor {
    hidden [hashtable] $_metrics = @{}
    hidden [int] $_commandCount = 0

    [void] RecordCommand([string]$command, [long]$durationMs, [bool]$success) {
        $this._commandCount++

        $key = $command.Split(' ')[0]  # Use first token as key
        if (-not $this._metrics.ContainsKey($key)) {
            $this._metrics[$key] = @{
                Count = 0
                TotalMs = 0
                Successes = 0
                Failures = 0
                AvgMs = 0
                MaxMs = 0
                MinMs = [long]::MaxValue
            }
        }

        $metric = $this._metrics[$key]
        $metric.Count++
        $metric.TotalMs += $durationMs

        if ($success) { $metric.Successes++ } else { $metric.Failures++ }

        $metric.AvgMs = [Math]::Round($metric.TotalMs / $metric.Count, 2)
        $metric.MaxMs = [Math]::Max($metric.MaxMs, $durationMs)
        $metric.MinMs = [Math]::Min($metric.MinMs, $durationMs)
    }

    [hashtable] GetMetrics() {
        return $this._metrics.Clone()
    }

    [int] GetCommandCount() {
        return $this._commandCount
    }

    [void] Reset() {
        $this._metrics.Clear()
        $this._commandCount = 0
    }
}

# Enhanced command processor with security and performance improvements
class PmcEnhancedCommandProcessor {
    hidden [PmcCommandPerformanceMonitor] $_perfMonitor
    hidden [hashtable] $_cache = @{}
    hidden [datetime] $_lastCacheClean = [datetime]::Now
    hidden [int] $_maxCacheSize = 100

    PmcEnhancedCommandProcessor() {
        $this._perfMonitor = [PmcCommandPerformanceMonitor]::new()
    }

    # Enhanced command execution with full pipeline
    [object] ExecuteCommand([string]$input) {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $success = $false
        $result = $null

        try {
            # Step 1: Input sanitization
            $sanitized = [PmcInputSanitizer]::SanitizeCommandInput($input)
            Write-PmcDebug -Level 3 -Category 'EnhancedProcessor' -Message "Input sanitized" -Data @{ Original = $input.Length; Sanitized = $sanitized.Length }

            # Step 2: Tokenization with safety validation
            $tokens = $this.SafeTokenize($sanitized)

            # Step 3: Context parsing with enhanced validation
            $context = $this.ParseEnhancedContext($tokens, $sanitized)

            # Step 4: Security validation
            $this.ValidateContextSecurity($context)

            # Step 5: Business logic validation
            $this.ValidateContextBusiness($context)

            if (-not $context.IsValid()) {
                throw "Validation failed: $($context.ValidationErrors -join '; ')"
            }

            # Step 6: Execute with performance monitoring
            $result = $this.ExecuteValidatedContext($context)
            $success = $true

            Write-PmcDebug -Level 2 -Category 'EnhancedProcessor' -Message "Command executed successfully" -Data @{ Domain = $context.Domain; Action = $context.Action; Duration = $stopwatch.ElapsedMilliseconds }

        } catch {
            Write-PmcDebug -Level 1 -Category 'EnhancedProcessor' -Message "Command execution failed" -Data @{ Error = $_.ToString(); Input = $input }
            $result = @{ Error = $_.ToString(); Success = $false }
        } finally {
            $stopwatch.Stop()
            $this._perfMonitor.RecordCommand($input, $stopwatch.ElapsedMilliseconds, $success)
            $this.CleanCacheIfNeeded()
        }

        return $result
    }

    # Safe tokenization with validation
    [string[]] SafeTokenize([string]$input) {
        $tokens = ConvertTo-PmcTokens $input

        foreach ($token in $tokens) {
            if (-not [PmcInputSanitizer]::ValidateTokenSafety($token)) {
                throw "Unsafe token detected: $token"
            }
        }

        return $tokens
    }

    # Enhanced context parsing
    [PmcEnhancedCommandContext] ParseEnhancedContext([string[]]$tokens, [string]$originalInput) {
        # Use existing parser as base, then enhance
        $parsed = ConvertTo-PmcContext $tokens

        if (-not $parsed.Success) {
            throw "Parse error: $($parsed.Error)"
        }

        # Create enhanced context
        $enhanced = [PmcEnhancedCommandContext]::new($parsed.Context.Domain, $parsed.Context.Action)
        $enhanced.Args = $parsed.Context.Args.Clone()
        $enhanced.FreeText = $parsed.Context.FreeText
        $enhanced.OriginalInput = $originalInput
        $enhanced.Metadata['Handler'] = $parsed.Handler

        return $enhanced
    }

    # Security validation layer
    [void] ValidateContextSecurity([PmcEnhancedCommandContext]$context) {
        # Validate domain and action are allowed
        $allowedDomains = @('task', 'project', 'time', 'help', 'config', 'query')
        if ($context.Domain -notin $allowedDomains) {
            $context.AddValidationError("Unknown domain: $($context.Domain)")
        }

        # Validate argument values for injection attempts
        foreach ($key in $context.Args.Keys) {
            $value = $context.Args[$key]
            if ($value -is [string]) {
                try {
                    [PmcInputSanitizer]::SanitizeCommandInput($value) | Out-Null
                } catch {
                    $context.AddValidationError("Unsafe argument value for $key`: $_")
                }
            }
        }

        # Validate free text
        foreach ($text in $context.FreeText) {
            if (-not [PmcInputSanitizer]::ValidateTokenSafety($text)) {
                $context.AddValidationError("Unsafe free text: $text")
            }
        }
    }

    # Business logic validation
    [void] ValidateContextBusiness([PmcEnhancedCommandContext]$context) {
        # Use existing validation but with enhanced error reporting
        try {
            $legacyContext = [PmcCommandContext]::new()
            $legacyContext.Domain = $context.Domain
            $legacyContext.Action = $context.Action
            $legacyContext.Args = $context.Args
            $legacyContext.FreeText = $context.FreeText

            Set-PmcContextDefaults -Context $legacyContext
            Normalize-PmcContextFields -Context $legacyContext

            $isValid = Test-PmcContext -Context $legacyContext
            if (-not $isValid) {
                $context.AddValidationError("Business logic validation failed")
            }

            # Copy back any normalized values
            $context.Args = $legacyContext.Args

        } catch {
            $context.AddValidationError("Business validation error: $_")
        }
    }

    # Execute validated context with enhanced error handling
    [object] ExecuteValidatedContext([PmcEnhancedCommandContext]$context) {
        # Prefer enhanced handler registry if available
        $legacyContext = [PmcCommandContext]::new()
        $legacyContext.Domain = $context.Domain
        $legacyContext.Action = $context.Action
        $legacyContext.Args = $context.Args
        $legacyContext.FreeText = $context.FreeText

        $usedEnhanced = $false
        try {
            if (Get-Command Get-PmcHandler -ErrorAction SilentlyContinue) {
                $desc = Get-PmcHandler -Domain $context.Domain -Action $context.Action
                if ($desc -and $desc.Execute) {
                    $usedEnhanced = $true
                    return (& $desc.Execute $legacyContext)
                }
            }
        } catch {}

        # Fall back to explicit handler name (must exist)
        $handler = $context.Metadata['Handler']
        if (-not (Get-Command -Name $handler -ErrorAction SilentlyContinue)) {
            throw "Handler not found: $handler"
        }

        return (& $handler -Context $legacyContext)
    }

    # Cache management
    [void] CleanCacheIfNeeded() {
        $now = [datetime]::Now
        if (($now - $this._lastCacheClean).TotalMinutes -gt 10 -or $this._cache.Count -gt $this._maxCacheSize) {
            $this._cache.Clear()
            $this._lastCacheClean = $now
            Write-PmcDebug -Level 3 -Category 'EnhancedProcessor' -Message "Cache cleaned"
        }
    }

    # Performance metrics
    [hashtable] GetPerformanceMetrics() {
        return $this._perfMonitor.GetMetrics()
    }

    [int] GetCommandCount() {
        return $this._perfMonitor.GetCommandCount()
    }

    [void] ResetMetrics() {
        $this._perfMonitor.Reset()
    }
}

# Global instance
$Script:PmcEnhancedCommandProcessor = $null

function Initialize-PmcEnhancedCommandProcessor {
    if ($Script:PmcEnhancedCommandProcessor) {
        Write-Warning "PMC Enhanced Command Processor already initialized"
        return
    }

    $Script:PmcEnhancedCommandProcessor = [PmcEnhancedCommandProcessor]::new()
    Write-PmcDebug -Level 2 -Category 'EnhancedProcessor' -Message "Enhanced command processor initialized"
}

function Get-PmcEnhancedCommandProcessor {
    if (-not $Script:PmcEnhancedCommandProcessor) {
        Initialize-PmcEnhancedCommandProcessor
    }
    return $Script:PmcEnhancedCommandProcessor
}

function Invoke-PmcEnhancedCommand {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Command
    )

    $processor = Get-PmcEnhancedCommandProcessor
    return $processor.ExecuteCommand($Command)
}

function Get-PmcCommandPerformanceStats {
    $processor = Get-PmcEnhancedCommandProcessor
    $metrics = $processor.GetPerformanceMetrics()
    $commandCount = $processor.GetCommandCount()

    Write-Host "PMC Command Performance Statistics" -ForegroundColor Green
    Write-Host "=================================" -ForegroundColor Green
    Write-Host "Total Commands: $commandCount"
    Write-Host ""

    if ($metrics.Count -gt 0) {
        $sorted = $metrics.GetEnumerator() | Sort-Object { $_.Value.Count } -Descending

        Write-Host "Top Commands by Usage:" -ForegroundColor Yellow
        Write-Host "Command".PadRight(15) + "Count".PadRight(8) + "Avg(ms)".PadRight(10) + "Max(ms)".PadRight(10) + "Success%" -ForegroundColor Cyan
        Write-Host ("-" * 50) -ForegroundColor Gray

        foreach ($entry in $sorted) {
            $cmd = $entry.Key
            $stats = $entry.Value
            $successRate = if ($stats.Count -gt 0) { [Math]::Round(($stats.Successes * 100.0) / $stats.Count, 1) } else { 0 }

            Write-Host ($cmd.PadRight(15) +
                      $stats.Count.ToString().PadRight(8) +
                      $stats.AvgMs.ToString().PadRight(10) +
                      $stats.MaxMs.ToString().PadRight(10) +
                      "$successRate%")
        }
    } else {
        Write-Host "No command statistics available yet."
    }
}

Export-ModuleMember -Function Initialize-PmcEnhancedCommandProcessor, Get-PmcEnhancedCommandProcessor, Invoke-PmcEnhancedCommand, Get-PmcCommandPerformanceStats


# END FILE: ./module/Pmc.Strict/Core/EnhancedCommandProcessor.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/Core/EnhancedDataValidator.ps1
# SIZE: 16.06 KB
# MODIFIED: 2025-09-21 15:24:50
# ================================================================================

# PMC Enhanced Data Validator - Comprehensive validation and sanitization
# Implements Phase 3 data validation improvements

Set-StrictMode -Version Latest

# Data validation rules and schemas
class PmcValidationRule {
    [string] $Name
    [string] $Type  # Required, Optional, Computed
    [scriptblock] $Validator
    [scriptblock] $Sanitizer
    [string] $ErrorMessage
    [hashtable] $Constraints = @{}

    PmcValidationRule([string]$name, [string]$type, [scriptblock]$validator) {
        $this.Name = $name
        $this.Type = $type
        $this.Validator = $validator
        $this.ErrorMessage = "Validation failed for field: $name"
    }

    [bool] Validate([object]$value) {
        try {
            return & $this.Validator $value
        } catch {
            Write-PmcDebug -Level 1 -Category 'Validation' -Message "Validation rule error for $($this.Name): $_"
            return $false
        }
    }

    [object] Sanitize([object]$value) {
        if ($this.Sanitizer) {
            try {
                return & $this.Sanitizer $value
            } catch {
                Write-PmcDebug -Level 1 -Category 'Validation' -Message "Sanitization failed for $($this.Name): $_"
                return $value
            }
        }
        return $value
    }
}

# Domain-specific validation schemas
class PmcDomainValidator {
    [string] $Domain
    [hashtable] $Rules = @{}
    [hashtable] $CrossFieldValidators = @{}

    PmcDomainValidator([string]$domain) {
        $this.Domain = $domain
        $this.InitializeRules()
    }

    [void] InitializeRules() {
        switch ($this.Domain) {
            'task' { $this.InitializeTaskRules() }
            'project' { $this.InitializeProjectRules() }
            'timelog' { $this.InitializeTimelogRules() }
        }
    }

    [void] InitializeTaskRules() {
        # Task ID validation
        $this.Rules['id'] = [PmcValidationRule]::new('id', 'Optional', {
            param($value)
            if ($null -eq $value) { return $true }
            return ($value -is [int] -and $value -gt 0) -or ($value -match '^\d+$' -and [int]$value -gt 0)
        })
        $this.Rules['id'].Sanitizer = { param($value) if ($value -match '^\d+$') { return [int]$value } else { return $value } }
        $this.Rules['id'].ErrorMessage = "Task ID must be a positive integer"

        # Task text validation
        $this.Rules['text'] = [PmcValidationRule]::new('text', 'Required', {
            param($value)
            return $value -and $value.ToString().Trim().Length -gt 0 -and $value.ToString().Length -le 500
        })
        $this.Rules['text'].Sanitizer = { param($value) return $value.ToString().Trim() }
        $this.Rules['text'].ErrorMessage = "Task text is required and must be 1-500 characters"

        # Project validation
        $this.Rules['project'] = [PmcValidationRule]::new('project', 'Optional', {
            param($value)
            if (-not $value) { return $true }
            $str = $value.ToString().Trim()
            return $str.Length -le 100 -and $str -notmatch '[<>|"*?\\/:]+' -and $str -notmatch '^\s*$'
        })
        $this.Rules['project'].Sanitizer = { param($value) if ($value) { return $value.ToString().Trim() } else { return $null } }
        $this.Rules['project'].ErrorMessage = "Project name must be valid and under 100 characters"

        # Due date validation
        $this.Rules['due'] = [PmcValidationRule]::new('due', 'Optional', {
            param($value)
            if (-not $value) { return $true }
            $str = $value.ToString()
            try {
                $parsed = [datetime]::Parse($str)
                return $parsed -ge [datetime]::Today.AddDays(-1)  # Allow yesterday and future
            } catch {
                return $false
            }
        })
        $this.Rules['due'].Sanitizer = {
            param($value)
            if ($value) {
                try {
                    return [datetime]::Parse($value.ToString()).ToString('yyyy-MM-dd')
                } catch {
                    return $null
                }
            }
            return $null
        }
        $this.Rules['due'].ErrorMessage = "Due date must be a valid date (yesterday or later)"

        # Priority validation
        $this.Rules['priority'] = [PmcValidationRule]::new('priority', 'Optional', {
            param($value)
            if (-not $value) { return $true }
            $str = $value.ToString().ToLower()
            return $str -in @('p1', 'p2', 'p3', 'high', 'medium', 'low', '1', '2', '3')
        })
        $this.Rules['priority'].Sanitizer = {
            param($value)
            if ($value) {
                $str = $value.ToString().ToLower()
                switch ($str) {
                    { $_ -in @('p1', 'high', '1') } { return 'p1' }
                    { $_ -in @('p2', 'medium', '2') } { return 'p2' }
                    { $_ -in @('p3', 'low', '3') } { return 'p3' }
                    default { return 'p2' }  # Default to medium
                }
            }
            return 'p2'
        }
        $this.Rules['priority'].ErrorMessage = "Priority must be p1/p2/p3, high/medium/low, or 1/2/3"

        # Tags validation
        $this.Rules['tags'] = [PmcValidationRule]::new('tags', 'Optional', {
            param($value)
            if (-not $value) { return $true }
            $tags = if ($value -is [array]) { $value } else { @($value) }
            foreach ($tag in $tags) {
                $str = $tag.ToString().Trim()
                if ($str.Length -gt 50 -or $str -match '[<>|"*?\\/:]+' -or $str -match '^\s*$') {
                    return $false
                }
            }
            return $true
        })
        $this.Rules['tags'].Sanitizer = {
            param($value)
            if ($value) {
                $tags = if ($value -is [array]) { $value } else { @($value) }
                return $tags | ForEach-Object { $_.ToString().Trim() } | Where-Object { $_ }
            }
            return @()
        }
        $this.Rules['tags'].ErrorMessage = "Tags must be valid strings under 50 characters each"
    }

    [void] InitializeProjectRules() {
        # Project name validation
        $this.Rules['name'] = [PmcValidationRule]::new('name', 'Required', {
            param($value)
            if (-not $value) { return $false }
            $str = $value.ToString().Trim()
            return $str.Length -gt 0 -and $str.Length -le 100 -and $str -notmatch '[<>|"*?\\/:]+' -and $str -notmatch '^\s*$'
        })
        $this.Rules['name'].Sanitizer = { param($value) return $value.ToString().Trim() }
        $this.Rules['name'].ErrorMessage = "Project name is required and must be 1-100 valid characters"

        # Description validation
        $this.Rules['description'] = [PmcValidationRule]::new('description', 'Optional', {
            param($value)
            if (-not $value) { return $true }
            return $value.ToString().Length -le 1000
        })
        $this.Rules['description'].Sanitizer = { param($value) if ($value) { return $value.ToString().Trim() } else { return $null } }
        $this.Rules['description'].ErrorMessage = "Description must be under 1000 characters"

        # Status validation
        $this.Rules['status'] = [PmcValidationRule]::new('status', 'Optional', {
            param($value)
            if (-not $value) { return $true }
            $str = $value.ToString().ToLower()
            return $str -in @('active', 'inactive', 'archived', 'completed')
        })
        $this.Rules['status'].Sanitizer = {
            param($value)
            if ($value) {
                return $value.ToString().ToLower()
            }
            return 'active'
        }
        $this.Rules['status'].ErrorMessage = "Status must be active, inactive, archived, or completed"
    }

    [void] InitializeTimelogRules() {
        # Task reference validation
        $this.Rules['task'] = [PmcValidationRule]::new('task', 'Required', {
            param($value)
            return ($value -is [int] -and $value -gt 0) -or ($value -match '^\d+$' -and [int]$value -gt 0)
        })
        $this.Rules['task'].Sanitizer = { param($value) if ($value -match '^\d+$') { return [int]$value } else { return $value } }
        $this.Rules['task'].ErrorMessage = "Task reference must be a positive integer"

        # Duration validation
        $this.Rules['duration'] = [PmcValidationRule]::new('duration', 'Optional', {
            param($value)
            if (-not $value) { return $true }
            # Accept formats like "1h", "30m", "1h30m", or decimal hours
            $str = $value.ToString()
            return $str -match '^(\d+h)?(\d+m)?$' -or $str -match '^\d+(\.\d+)?$'
        })
        $this.Rules['duration'].Sanitizer = {
            param($value)
            if ($value) {
                $str = $value.ToString()
                # Convert to decimal hours
                if ($str -match '^(\d+)h(\d+)m$') {
                    return [decimal]$matches[1] + ([decimal]$matches[2] / 60)
                } elseif ($str -match '^(\d+)h$') {
                    return [decimal]$matches[1]
                } elseif ($str -match '^(\d+)m$') {
                    return [decimal]$matches[1] / 60
                } elseif ($str -match '^\d+(\.\d+)?$') {
                    return [decimal]$str
                }
            }
            return $null
        }
        $this.Rules['duration'].ErrorMessage = "Duration must be in format like '1h30m' or decimal hours"
    }

    [hashtable] ValidateData([hashtable]$data) {
        $result = @{
            IsValid = $true
            Errors = @()
            Warnings = @()
            SanitizedData = @{}
        }

        # Validate each field
        foreach ($field in $data.Keys) {
            $value = $data[$field]

            if ($this.Rules.ContainsKey($field)) {
                $rule = $this.Rules[$field]

                # Sanitize first
                $sanitized = $rule.Sanitize($value)
                $result.SanitizedData[$field] = $sanitized

                # Then validate
                if (-not $rule.Validate($sanitized)) {
                    $result.IsValid = $false
                    $result.Errors += $rule.ErrorMessage
                }
            } else {
                # Unknown field - add warning but allow
                $result.Warnings += "Unknown field: $field"
                $result.SanitizedData[$field] = $value
            }
        }

        # Check required fields
        $requiredFields = $this.Rules.Values | Where-Object { $_.Type -eq 'Required' } | ForEach-Object { $_.Name }
        foreach ($required in $requiredFields) {
            if (-not $data.ContainsKey($required) -or -not $data[$required]) {
                $result.IsValid = $false
                $result.Errors += "Required field missing: $required"
            }
        }

        # Run cross-field validation
        foreach ($validator in $this.CrossFieldValidators.Values) {
            $crossResult = & $validator $result.SanitizedData
            if (-not $crossResult.IsValid) {
                $result.IsValid = $false
                $result.Errors += $crossResult.Errors
            }
        }

        return $result
    }
}

# Enhanced validation engine with caching and performance monitoring
class PmcEnhancedDataValidator {
    hidden [hashtable] $_domainValidators = @{}
    hidden [hashtable] $_validationStats = @{
        TotalValidations = 0
        SuccessfulValidations = 0
        FailedValidations = 0
        TotalDuration = 0
    }

    PmcEnhancedDataValidator() {
        $this.InitializeDomainValidators()
    }

    [void] InitializeDomainValidators() {
        $this._domainValidators['task'] = [PmcDomainValidator]::new('task')
        $this._domainValidators['project'] = [PmcDomainValidator]::new('project')
        $this._domainValidators['timelog'] = [PmcDomainValidator]::new('timelog')
    }

    [hashtable] ValidateData([string]$domain, [hashtable]$data) {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $this._validationStats.TotalValidations++

        try {
            if (-not $this._domainValidators.ContainsKey($domain)) {
                return @{
                    IsValid = $false
                    Errors = @("Unknown domain: $domain")
                    Warnings = @()
                    SanitizedData = $data
                }
            }

            $validator = $this._domainValidators[$domain]
            $result = $validator.ValidateData($data)

            if ($result.IsValid) {
                $this._validationStats.SuccessfulValidations++
            } else {
                $this._validationStats.FailedValidations++
            }

            Write-PmcDebug -Level 3 -Category 'EnhancedValidator' -Message "Data validation completed" -Data @{
                Domain = $domain
                IsValid = $result.IsValid
                ErrorCount = $result.Errors.Count
                WarningCount = $result.Warnings.Count
                Duration = $stopwatch.ElapsedMilliseconds
            }

            return $result

        } catch {
            $this._validationStats.FailedValidations++
            Write-PmcDebug -Level 1 -Category 'EnhancedValidator' -Message "Validation error: $_" -Data @{ Domain = $domain }

            return @{
                IsValid = $false
                Errors = @("Validation system error: $_")
                Warnings = @()
                SanitizedData = $data
            }

        } finally {
            $stopwatch.Stop()
            $this._validationStats.TotalDuration += $stopwatch.ElapsedMilliseconds
        }
    }

    [hashtable] GetValidationStats() {
        $avgDuration = if ($this._validationStats.TotalValidations -gt 0) {
            [Math]::Round($this._validationStats.TotalDuration / $this._validationStats.TotalValidations, 2)
        } else { 0 }

        $successRate = if ($this._validationStats.TotalValidations -gt 0) {
            [Math]::Round(($this._validationStats.SuccessfulValidations * 100.0) / $this._validationStats.TotalValidations, 2)
        } else { 0 }

        return @{
            TotalValidations = $this._validationStats.TotalValidations
            SuccessfulValidations = $this._validationStats.SuccessfulValidations
            FailedValidations = $this._validationStats.FailedValidations
            SuccessRate = $successRate
            AverageDuration = $avgDuration
            TotalDuration = $this._validationStats.TotalDuration
        }
    }

    [void] ResetStats() {
        $this._validationStats = @{
            TotalValidations = 0
            SuccessfulValidations = 0
            FailedValidations = 0
            TotalDuration = 0
        }
    }
}

# Global instance
$Script:PmcEnhancedDataValidator = $null

function Initialize-PmcEnhancedDataValidator {
    if ($Script:PmcEnhancedDataValidator) {
        Write-Warning "PMC Enhanced Data Validator already initialized"
        return
    }

    $Script:PmcEnhancedDataValidator = [PmcEnhancedDataValidator]::new()
    Write-PmcDebug -Level 2 -Category 'EnhancedValidator' -Message "Enhanced data validator initialized"
}

function Test-PmcEnhancedData {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Domain,

        [Parameter(Mandatory=$true)]
        [hashtable]$Data
    )

    if (-not $Script:PmcEnhancedDataValidator) {
        Initialize-PmcEnhancedDataValidator
    }

    return $Script:PmcEnhancedDataValidator.ValidateData($Domain, $Data)
}

function Get-PmcDataValidationStats {
    if (-not $Script:PmcEnhancedDataValidator) {
        Write-Host "Enhanced data validator not initialized"
        return
    }

    $stats = $Script:PmcEnhancedDataValidator.GetValidationStats()

    Write-Host "PMC Data Validation Statistics" -ForegroundColor Green
    Write-Host "=============================" -ForegroundColor Green
    Write-Host "Total Validations: $($stats.TotalValidations)"
    Write-Host "Successful: $($stats.SuccessfulValidations)"
    Write-Host "Failed: $($stats.FailedValidations)"
    Write-Host "Success Rate: $($stats.SuccessRate)%"
    Write-Host "Average Duration: $($stats.AverageDuration) ms"
    Write-Host "Total Duration: $($stats.TotalDuration) ms"
}

Export-ModuleMember -Function Initialize-PmcEnhancedDataValidator, Test-PmcEnhancedData, Get-PmcDataValidationStats

# END FILE: ./module/Pmc.Strict/Core/EnhancedDataValidator.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/Core/EnhancedErrorHandler.ps1
# SIZE: 19.08 KB
# MODIFIED: 2025-09-21 15:27:20
# ================================================================================

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

# END FILE: ./module/Pmc.Strict/Core/EnhancedErrorHandler.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/Core/EnhancedQueryEngine.ps1
# SIZE: 33.39 KB
# MODIFIED: 2025-09-21 23:01:23
# ================================================================================

# PMC Enhanced Query Engine - Optimized query parsing and execution
# Implements Phase 3 query language improvements

Set-StrictMode -Version Latest

# Enhanced query specification with validation and optimization
class PmcEnhancedQuerySpec {
    [string] $Domain
    [string[]] $RawTokens = @()
    [hashtable] $Filters = @{}
    [hashtable] $Directives = @{}
    [hashtable] $Metadata = @{}
    [bool] $IsOptimized = $false
    [string[]] $ValidationErrors = @()
    [datetime] $ParseTime = [datetime]::Now

    # Query optimization hints
    [bool] $UseIndex = $false
    [string[]] $IndexFields = @()
    [int] $EstimatedRows = -1
    [string] $OptimizationStrategy = 'default'

    [void] AddValidationError([string]$error) {
        $this.ValidationErrors += $error
    }

    [bool] IsValid() {
        return $this.ValidationErrors.Count -eq 0
    }

    [void] MarkOptimized([string]$strategy) {
        $this.IsOptimized = $true
        $this.OptimizationStrategy = $strategy
    }
}

# AST model for enhanced queries (typed, structured)
class PmcAstNode { }
class PmcAstFilterNode : PmcAstNode {
    [string] $Field
    [string] $Operator
    [string] $Value
    PmcAstFilterNode([string]$f,[string]$op,[string]$v){ $this.Field=$f; $this.Operator=$op; $this.Value=$v }
}
class PmcAstDirectiveNode : PmcAstNode {
    [string] $Name
    [object] $Value
    PmcAstDirectiveNode([string]$n,[object]$v){ $this.Name=$n; $this.Value=$v }
}
class PmcAstQuery : PmcAstNode {
    [string] $Domain
    [System.Collections.Generic.List[PmcAstFilterNode]] $Filters
    [System.Collections.Generic.List[PmcAstDirectiveNode]] $Directives
    [string[]] $SearchTerms
    PmcAstQuery(){ $this.Filters = [System.Collections.Generic.List[PmcAstFilterNode]]::new(); $this.Directives=[System.Collections.Generic.List[PmcAstDirectiveNode]]::new(); $this.SearchTerms=@() }
}

# Query cache for performance optimization
class PmcQueryCache {
    hidden [hashtable] $_cache = @{}
    hidden [int] $_maxSize = 50
    hidden [hashtable] $_stats = @{
        Hits = 0
        Misses = 0
        Evictions = 0
    }

    [string] GenerateCacheKey([PmcEnhancedQuerySpec]$spec) {
        $keyParts = @(
            $spec.Domain,
            ($spec.RawTokens -join '|'),
            ($spec.Filters.GetEnumerator() | Sort-Object Key | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '&',
            ($spec.Directives.GetEnumerator() | Sort-Object Key | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join '&'
        )
        return ($keyParts -join '::')
    }

    [object] Get([string]$key) {
        if ($this._cache.ContainsKey($key)) {
            $entry = $this._cache[$key]
            if (([datetime]::Now - $entry.Timestamp).TotalMinutes -lt 5) {
                $this._stats.Hits++
                $entry.LastAccess = [datetime]::Now
                return $entry.Result
            } else {
                $this._cache.Remove($key)
            }
        }
        $this._stats.Misses++
        return $null
    }

    [void] Set([string]$key, [object]$result) {
        if ($this._cache.Count -ge $this._maxSize) {
            $this.EvictOldest()
        }

        $this._cache[$key] = @{
            Result = $result
            Timestamp = [datetime]::Now
            LastAccess = [datetime]::Now
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
            $this._stats.Evictions++
        }
    }

    [hashtable] GetStats() {
        $total = $this._stats.Hits + $this._stats.Misses
        $hitRate = if ($total -gt 0) { [Math]::Round(($this._stats.Hits * 100.0) / $total, 2) } else { 0 }

        return @{
            Size = $this._cache.Count
            Hits = $this._stats.Hits
            Misses = $this._stats.Misses
            Evictions = $this._stats.Evictions
            HitRate = $hitRate
        }
    }

    [void] Clear() {
        $this._cache.Clear()
        $this._stats = @{ Hits = 0; Misses = 0; Evictions = 0 }
    }
}

# Enhanced query parser with validation and optimization
class PmcEnhancedQueryParser {
    hidden [hashtable] $_allowedDomains = @{
        'task' = @('id', 'text', 'project', 'due', 'priority', 'status', 'tags')
        'project' = @('name', 'description', 'status', 'created', 'updated')
        'timelog' = @('id', 'task', 'project', 'start', 'end', 'duration', 'description')
    }

    hidden [hashtable] $_optimizationRules = @{
        'task' = @{
            'id' = 'index'
            'project' = 'index'
            'due' = 'range'
            'priority' = 'category'
        }
        'project' = @{
            'name' = 'index'
            'status' = 'category'
        }
        'timelog' = @{
            'task' = 'index'
            'project' = 'index'
            'start' = 'range'
        }
    }

    [PmcEnhancedQuerySpec] ParseQuery([string[]]$tokens) {
        $spec = [PmcEnhancedQuerySpec]::new()
        $ast = [PmcAstQuery]::new()

        if ($tokens.Count -eq 0) {
            $spec.AddValidationError("Query requires at least a domain")
            return $spec
        }

        # Parse domain (first token)
        $domainToken = $tokens[0].ToLower()
        $spec.Domain = $this.NormalizeDomain($domainToken)
        $ast.Domain = $spec.Domain

        if (-not $spec.Domain) {
            $spec.AddValidationError("Unknown domain: $domainToken")
            return $spec
        }

        if (-not $this._allowedDomains.ContainsKey($spec.Domain)) {
            $spec.AddValidationError("Domain not supported: $($spec.Domain)")
            return $spec
        }

        # Parse remaining tokens
        $spec.RawTokens = $tokens | Select-Object -Skip 1
        $this.ParseTokens($spec, $spec.RawTokens)
        # Build AST nodes from parsed spec
        foreach ($field in $spec.Filters.Keys) { foreach ($f in $spec.Filters[$field]) { [void]$ast.Filters.Add([PmcAstFilterNode]::new($field,[string]$f.Operator,[string]$f.Value)) } }
        foreach ($k in $spec.Directives.Keys) { [void]$ast.Directives.Add([PmcAstDirectiveNode]::new($k,$spec.Directives[$k])) }
        if ($spec.Metadata.ContainsKey('search')) { $ast.SearchTerms = @($spec.Metadata['search']) }
        $spec.Metadata['Ast'] = $ast

        # Apply optimization hints
        $this.OptimizeQuery($spec)

        return $spec
    }

    [string] NormalizeDomain([string]$domain) {
        switch ($domain) {
            { $_ -in @('task', 'tasks') } { return 'task' }
            { $_ -in @('project', 'projects') } { return 'project' }
            { $_ -in @('timelog', 'timelogs', 'time') } { return 'timelog' }
            default { return $null }
        }
        # Fallback (should never reach here)
        return $null
    }

    [void] ParseTokens([PmcEnhancedQuerySpec]$spec, [string[]]$tokens) {
        $allowedFields = $this._allowedDomains[$spec.Domain]

        foreach ($token in $tokens) {
            if ([string]::IsNullOrWhiteSpace($token)) { continue }

            if ($token.StartsWith('@')) {
                $proj = $token.Substring(1).Trim('"')
                if (-not $spec.Filters.ContainsKey('project')) { $spec.Filters['project'] = @() }
                $spec.Filters['project'] += @{ Operator = '='; Value = $proj }
                continue
            }

            if ($token.StartsWith('#')) {
                $tag = $token.Substring(1).Trim('"')
                if (-not $spec.Filters.ContainsKey('tags')) { $spec.Filters['tags'] = @() }
                $spec.Filters['tags'] += @{ Operator = 'contains'; Value = $tag }
                continue
            }

            if ($token -match '^(?i)p(\d+)$') {
                $val = $matches[1]
                if (-not $spec.Filters.ContainsKey('priority')) { $spec.Filters['priority'] = @() }
                $spec.Filters['priority'] += @{ Operator = '='; Value = $val }
                continue
            }
            if ($token -match '^(?i)p([<>]=?)(\d+)$') {
                $op = $matches[1]; $val = $matches[2]
                if (-not $spec.Filters.ContainsKey('priority')) { $spec.Filters['priority'] = @() }
                $spec.Filters['priority'] += @{ Operator = $op; Value = $val }
                continue
            }
            if ($token -match '^(?i)p(\d+)\.\.(\d+)$') {
                $low = $matches[1]; $high = $matches[2]
                if (-not $spec.Filters.ContainsKey('priority')) { $spec.Filters['priority'] = @() }
                $spec.Filters['priority'] += @{ Operator = '>='; Value = $low }
                $spec.Filters['priority'] += @{ Operator = '<='; Value = $high }
                continue
            }

            if ($spec.Domain -eq 'task' -and $token -in @('overdue','today','tomorrow')) {
                if (-not $spec.Filters.ContainsKey('due')) { $spec.Filters['due'] = @() }
                $spec.Filters['due'] += @{ Operator = ':'; Value = $token }
                continue
            }
            # Directives (cols:, sort:, etc.)
            if ($token -match '^(cols?|columns?):(.+)$') {
                $spec.Directives['columns'] = $matches[2] -split ','
                continue
            }

            if ($token -match '^sort:(.+)$') {
                $spec.Directives['sort'] = $matches[1]
                continue
            }

            if ($token -match '^limit:(\d+)$') {
                $spec.Directives['limit'] = [int]$matches[1]
                continue
            }

            if ($token -match '^group:(.+)$') {
                $spec.Directives['groupBy'] = $matches[1]
                continue
            }

            # Field filters (field:value or field>value, etc.)
            if ($token -match '^(\w+)([:]|>=|<=|=|>|<|~)(.+)$') {
                $field = $matches[1].ToLower()
                $operator = $matches[2]
                $value = $matches[3]

                if ($field -notin $allowedFields) {
                    $spec.AddValidationError("Unknown field for $($spec.Domain): $field")
                    continue
                }

                # Validate operator
                if ($operator -notin @(':', '=', '>', '<', '>=', '<=', '~')) {
                    $spec.AddValidationError("Unknown operator: $operator")
                    continue
                }

                # Sanitize value
                if ($value.Length -gt 100) {
                    $spec.AddValidationError("Filter value too long: $field")
                    continue
                }

                if (-not $spec.Filters.ContainsKey($field)) {
                    $spec.Filters[$field] = @()
                }
                $spec.Filters[$field] += @{ Operator = $operator; Value = $value }
                continue
            }

            # Simple field names (for existence checks)
            if ($token -match '^\w+$' -and $token.ToLower() -in $allowedFields) {
                $field = $token.ToLower()
                if (-not $spec.Filters.ContainsKey($field)) {
                    $spec.Filters[$field] = @()
                }
                $spec.Filters[$field] += @{ Operator = 'exists'; Value = $true }
                continue
            }

            # Free text search
            if (-not $spec.Metadata.ContainsKey('search')) {
                $spec.Metadata['search'] = @()
            }
            $spec.Metadata['search'] += $token
        }
    }

    [void] OptimizeQuery([PmcEnhancedQuerySpec]$spec) {
        if (-not $this._optimizationRules.ContainsKey($spec.Domain)) {
            return
        }

        $rules = $this._optimizationRules[$spec.Domain]
        $indexableFields = @()
        $strategy = 'scan'

        # Check for indexed fields in filters
        foreach ($field in $spec.Filters.Keys) {
            if ($rules.ContainsKey($field) -and $rules[$field] -eq 'index') {
                $indexableFields += $field
                $strategy = 'index'
            }
        }

        if ($indexableFields.Count -gt 0) {
            $spec.UseIndex = $true
            $spec.IndexFields = $indexableFields
            $spec.MarkOptimized($strategy)
        }

        # Estimate result size
        if ($spec.Filters.ContainsKey('id')) {
            $spec.EstimatedRows = 1
        } elseif ($indexableFields.Count -gt 0) {
            $spec.EstimatedRows = 10  # Rough estimate for indexed queries
        } else {
            $spec.EstimatedRows = 100  # Full scan estimate
        }
    }
}

# Enhanced query executor with performance optimization
class PmcEnhancedQueryExecutor {
    hidden [PmcQueryCache] $_cache
    hidden [hashtable] $_executionStats = @{
        QueriesExecuted = 0
        TotalDuration = 0
        CacheHits = 0
        CacheMisses = 0
    }

    PmcEnhancedQueryExecutor() {
        $this._cache = [PmcQueryCache]::new()
    }

    [object] ExecuteQuery([PmcEnhancedQuerySpec]$spec) {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        try {
            # Check cache first
            $cacheKey = $this._cache.GenerateCacheKey($spec)
            $cached = $this._cache.Get($cacheKey)

            if ($cached) {
                $this._executionStats.CacheHits++
                Write-PmcDebug -Level 3 -Category 'EnhancedQuery' -Message "Cache hit for query" -Data @{ Domain = $spec.Domain; Strategy = 'cache' }
                return $cached
            }

            $this._executionStats.CacheMisses++

            # Execute AST first (normalizes spec), then execute optimized path
            $result = $this.ExecuteAst($spec)

            # Cache successful results
            if ($result -and -not $result.Error) {
                $this._cache.Set($cacheKey, $result)
            }

            $this._executionStats.QueriesExecuted++
            $this._executionStats.TotalDuration += $stopwatch.ElapsedMilliseconds

            Write-PmcDebug -Level 2 -Category 'EnhancedQuery' -Message "Query executed" -Data @{
                Domain = $spec.Domain
                Strategy = $spec.OptimizationStrategy
                Duration = $stopwatch.ElapsedMilliseconds
                Cached = $false
                Results = if ($result.Data) { $result.Data.Count } else { 0 }
            }

            return $result

        } catch {
            Write-PmcDebug -Level 1 -Category 'EnhancedQuery' -Message "Query execution failed" -Data @{ Error = $_.ToString(); Domain = $spec.Domain }
            return @{ Error = $_.ToString(); Success = $false }
        } finally {
            $stopwatch.Stop()
        }
    }

    [object] ExecuteAst([PmcEnhancedQuerySpec]$spec) {
        try {
            if (-not $spec.Metadata.ContainsKey('Ast')) { return $this.ExecuteScanQuery($spec) }
            $ast = [PmcAstQuery]$spec.Metadata['Ast']
            if ($null -eq $ast) { return $this.ExecuteScanQuery($spec) }

            # 1) Resolve dataset
            $data = switch ($ast.Domain) {
                'task'    { if (Get-Command Get-PmcTasksData -ErrorAction SilentlyContinue)    { Get-PmcTasksData }    else { @() } }
                'project' { if (Get-Command Get-PmcProjectsData -ErrorAction SilentlyContinue) { Get-PmcProjectsData } else { @() } }
                'timelog' { if (Get-Command Get-PmcTimeLogsData -ErrorAction SilentlyContinue) { Get-PmcTimeLogsData } else { @() } }
                default { @() }
            }

            $filtered = @($data)

            # 2) Apply filters (AND semantics)
            foreach ($node in $ast.Filters) {
                $field = $node.Field; $op = ($node.Operator + '') ; $val = ($node.Value + '')
                $filtered = @($filtered | Where-Object {
                    if ($null -eq $_) { return $false }
                    $has = $_.PSObject.Properties[$field]
                    $v = if ($has) { $_."$field" } else { $null }

                    # Special: due date filters
                    if ($field -eq 'due') {
                        $today = (Get-Date).Date
                        if ($op -eq ':' -and $val -eq 'today') { if (-not $v) { return $false }; try { return ([datetime]$v).Date -eq $today } catch { return $false } }
                        if ($op -eq ':' -and $val -eq 'tomorrow') { if (-not $v) { return $false }; try { return ([datetime]$v).Date -eq $today.AddDays(1) } catch { return $false } }
                        if ($op -eq ':' -and $val -eq 'overdue') { if (-not $v) { return $false }; try { return ([datetime]$v).Date -lt $today } catch { return $false } }
                        if ($op -eq ':' -and $val -match '^\+(\d+)$') { if (-not $v) { return $false }; $d=[int]$matches[1]; try { $date=[datetime]$v; return ($date.Date -le $today.AddDays($d)) -and ($date.Date -ge $today) } catch { return $false } }
                        if ($op -eq ':' -and $val -eq 'eow') { if (-not $v) { return $false }; $dow=[int]$today.DayOfWeek; $rem=(7-$dow)%7; try { return ([datetime]$v).Date -le $today.AddDays($rem) -and ([datetime]$v).Date -ge $today } catch { return $false } }
                        if ($op -eq ':' -and $val -eq 'eom') { if (-not $v) { return $false }; $eom=(Get-Date -Day 1).AddMonths(1).AddDays(-1).Date; try { return ([datetime]$v).Date -le $eom -and ([datetime]$v).Date -ge $today } catch { return $false } }
                        # support YYYYMMDD/YYMMDD quick parse
                        if ($op -eq ':' -and $val -match '^(\d{8}|\d{6})$') { if (-not $v) { return $false }; try { $dt=[datetime]$v; $y=$val; if ($y.Length -eq 8) { $qry=[datetime]::ParseExact($y,'yyyyMMdd',$null) } else { $qry=[datetime]::ParseExact($y,'yyMMdd',$null) }; return $dt.Date -eq $qry.Date } catch { return $false } }
                        $sv = if ($v) { [string]$v } else { '' }
                        return $sv -match [regex]::Escape($val)
                    }

                    # Special: tags contains
                    if ($field -eq 'tags') {
                        $arr=@(); try { if ($v -is [System.Collections.IEnumerable]) { $arr=@($v) } } catch {}
                        if ($op -eq 'contains') { return ($arr -contains $val) }
                        return $false
                    }

                    $sv = if ($v -ne $null) { [string]$v } else { '' }
                    switch ($op) {
                        'exists' { $has -and $sv -ne '' }
                        ':' { $sv -match [regex]::Escape($val) }
                        '=' { $sv -eq $val }
                        '>' { try { [double]$sv -gt [double]$val } catch { $false } }
                        '<' { try { [double]$sv -lt [double]$val } catch { $false } }
                        '>=' { try { [double]$sv -ge [double]$val } catch { $false } }
                        '<=' { try { [double]$sv -le [double]$val } catch { $false } }
                        '~' { $sv -like "*${val}*" }
                        default { $true }
                    }
                })
            }

            # 3) Apply free text search
            if ($ast.SearchTerms -and @($ast.SearchTerms).Count -gt 0) {
                foreach ($t in $ast.SearchTerms) {
                    $needle = ($t + '').ToLower()
                    $filtered = @($filtered | Where-Object {
                        $text = ''
                        try { $text = (($_.text) + ' ' + ($_.project) + ' ' + ($_.description) + ' ' + ($_.name)) } catch {}
                        $text.ToLower().Contains($needle)
                    })
                }
            }

            # 4) Apply directives: sort, group, columns, limit
            $dirMap = @{}
            foreach ($d in $ast.Directives) { $dirMap[$d.Name] = $d.Value }

            # Sort
            if ($dirMap.ContainsKey('sort')) {
                $sortExpr = [string]$dirMap['sort']; $asc = $true; $field = $sortExpr
                if ($sortExpr -match '^(.+?)([+-])$') { $field=$matches[1]; $asc = ($matches[2] -eq '+') }
                $filtered = @($filtered | Sort-Object -Property @{ Expression = { if ($_.PSObject.Properties[$field]) { $_."$field" } else { $null } }; Ascending = $asc })
            }

            # Group
            $grouped = $false
            if ($dirMap.ContainsKey('groupBy')) {
                $g = [string]$dirMap['groupBy']
                $projected = @()
                foreach ($row in $filtered) {
                    if ($null -eq $row) { continue }
                    $groupVal = if ($row.PSObject.Properties[$g]) { $row."$g" } else { $null }
                    $obj = [pscustomobject]@{ Group = $groupVal }
                    foreach ($p in $row.PSObject.Properties) { Add-Member -InputObject $obj -NotePropertyName $p.Name -NotePropertyValue $p.Value -Force }
                    $projected += $obj
                }
                $filtered = @($projected | Sort-Object -Property @{ Expression = { $_.Group } })
                $grouped = $true
            }

            # Columns
            if ($dirMap.ContainsKey('columns')) {
                $cols = @($dirMap['columns'])
                $projected = @()
                foreach ($row in $filtered) {
                    $obj = [pscustomobject]@{}
                    if ($grouped) { Add-Member -InputObject $obj -NotePropertyName 'Group' -NotePropertyValue $row.Group -Force }
                    foreach ($c in $cols) {
                        $name = [string]$c
                        $val = if ($row.PSObject.Properties[$name]) { $row."$name" } else { $null }
                        Add-Member -InputObject $obj -NotePropertyName $name -NotePropertyValue $val -Force
                    }
                    $projected += $obj
                }
                $filtered = $projected
            } elseif ($grouped) {
                # ensure Group column visible when grouped
                $projected = @()
                foreach ($row in $filtered) {
                    $obj = [pscustomobject]@{ Group = $row.Group }
                    foreach ($p in $row.PSObject.Properties) { if ($p.Name -ne 'Group') { Add-Member -InputObject $obj -NotePropertyName $p.Name -NotePropertyValue $p.Value -Force } }
                    $projected += $obj
                }
                $filtered = $projected
            }

            # Limit
            if ($dirMap.ContainsKey('limit')) { $n = [int]$dirMap['limit']; $filtered = @($filtered | Select-Object -First $n) }

            return @{
                Success = $true
                Data = ,$filtered
                Metadata = @{
                    EstimatedRows = $spec.EstimatedRows
                    ActualRows = @($filtered).Count
                    Strategy = $spec.OptimizationStrategy
                    Cached = $false
                }
            }
        } catch {
            Write-PmcDebug -Level 2 -Category 'EnhancedQuery' -Message "AST execution fallback: $_"
            return $this.ExecuteScanQuery($spec)
        }
    }

    [object] ExecuteIndexedQuery([PmcEnhancedQuerySpec]$spec) {
        # Indexed path – we still filter in-memory but can apply early prunes by index fields
        return $this.ExecuteScanQuery($spec)
    }

    [object] ExecuteScanQuery([PmcEnhancedQuerySpec]$spec) {
        # Execute against in-memory data from Storage via pure providers
        $data = switch ($spec.Domain) {
            'task'    { if (Get-Command Get-PmcTasksData -ErrorAction SilentlyContinue)    { Get-PmcTasksData }    else { @() } }
            'project' { if (Get-Command Get-PmcProjectsData -ErrorAction SilentlyContinue) { Get-PmcProjectsData } else { @() } }
            'timelog' { if (Get-Command Get-PmcTimeLogsData -ErrorAction SilentlyContinue) { Get-PmcTimeLogsData } else { @() } }
            default { @() }
        }

        # Apply filters
        $filtered = @($data)
        foreach ($field in $spec.Filters.Keys) {
            $ops = $spec.Filters[$field]
            foreach ($op in $ops) {
                $operator = [string]$op.Operator
                $val = [string]$op.Value
                $filtered = @($filtered | Where-Object {
                    if ($null -eq $_) { return $false }
                    $has = $_.PSObject.Properties[$field]
                    $v = if ($has) { $_."$field" } else { $null }
                    # Special cases
                    if ($field -eq 'due') {
                        $today = (Get-Date).Date
                        if ($val -eq 'today') { if (-not $v) { return $false }; try { return ([datetime]$v).Date -eq $today } catch { return $false } }
                        if ($val -eq 'tomorrow') { if (-not $v) { return $false }; try { return ([datetime]$v).Date -eq $today.AddDays(1) } catch { return $false } }
                        if ($val -eq 'overdue') { if (-not $v) { return $false }; try { return ([datetime]$v).Date -lt $today } catch { return $false } }
                        if ($val -match '^\+(\d+)$') { if (-not $v) { return $false }; $d=[int]$matches[1]; try { $date=[datetime]$v; return ($date.Date -le $today.AddDays($d)) -and ($date.Date -ge $today) } catch { return $false } }
                        if ($val -eq 'eow') { if (-not $v) { return $false }; $dow = [int]$today.DayOfWeek; $rem = (7 - $dow) % 7; try { return ([datetime]$v).Date -le $today.AddDays($rem) -and ([datetime]$v).Date -ge $today } catch { return $false } }
                        if ($val -eq 'eom') { if (-not $v) { return $false }; $eom = (Get-Date -Day 1).AddMonths(1).AddDays(-1).Date; try { return ([datetime]$v).Date -le $eom -and ([datetime]$v).Date -ge $today } catch { return $false } }
                        $vv = if ($v) { [string]$v } else { '' }
                        return $vv -match [regex]::Escape($val)
                    }
                    if ($field -eq 'tags') {
                        $arr = @(); try { if ($v -is [System.Collections.IEnumerable]) { $arr=@($v) } } catch {}
                        if ($operator -eq 'contains') { return ($arr -contains $val) }
                        return $false
                    }
                    $sv = if ($v -ne $null) { [string]$v } else { '' }
                    switch ($operator) {
                        'exists' { $has -and $sv -ne '' }
                        ':' { $sv -match [regex]::Escape($val) }
                        '=' { $sv -eq $val }
                        '>' { try { [double]$sv -gt [double]$val } catch { $false } }
                        '<' { try { [double]$sv -lt [double]$val } catch { $false } }
                        '>=' { try { [double]$sv -ge [double]$val } catch { $false } }
                        '<=' { try { [double]$sv -le [double]$val } catch { $false } }
                        '~' { $sv -like "*${val}*" }
                        default { $true }
                    }
                })
            }
        }

        # Free text search across common fields
        if ($spec.Metadata.ContainsKey('search')) {
            $terms = @($spec.Metadata['search'])
            foreach ($t in $terms) {
                $needle = $t.ToLower()
                $filtered = @($filtered | Where-Object {
                    $text = ''
                    try {
                        $text = (($_.text) + ' ' + ($_.project) + ' ' + ($_.description) + ' ' + ($_.name))
                    } catch {}
                    $text.ToLower().Contains($needle)
                })
            }
        }

        # Sorting
        if ($spec.Directives.ContainsKey('sort')) {
            $sortExpr = [string]$spec.Directives['sort']
            $asc = $true
            $field = $sortExpr
            if ($sortExpr -match '^(.+?)([+-])$') { $field = $matches[1]; $asc = ($matches[2] -eq '+') }
            $filtered = @($filtered | Sort-Object -Property @{ Expression = { if ($_.PSObject.Properties[$field]) { $_."$field" } else { $null } }; Ascending = $asc })
        }

        # Grouping (flat projection by adding Group field)
        if ($spec.Directives.ContainsKey('groupBy')) {
            $g = [string]$spec.Directives['groupBy']
            $projected = @()
            foreach ($row in $filtered) {
                if ($null -eq $row) { continue }
                $groupVal = if ($row.PSObject.Properties[$g]) { $row."$g" } else { $null }
                $obj = [pscustomobject]@{ Group = $groupVal }
                # Copy existing fields
                foreach ($p in $row.PSObject.Properties) { Add-Member -InputObject $obj -NotePropertyName $p.Name -NotePropertyValue $p.Value -Force }
                $projected += $obj
            }
            $filtered = @($projected | Sort-Object -Property @{ Expression = { $_.Group } })
        }

        # Columns selection
        if ($spec.Directives.ContainsKey('columns')) {
            $cols = @($spec.Directives['columns'])
            $projected = @()
            foreach ($row in $filtered) {
                $obj = [pscustomobject]@{}
                if ($spec.Directives.ContainsKey('groupBy')) { Add-Member -InputObject $obj -NotePropertyName 'Group' -NotePropertyValue $row.Group -Force }
                foreach ($c in $cols) {
                    $name = [string]$c
                    $val = if ($row.PSObject.Properties[$name]) { $row."$name" } else { $null }
                    Add-Member -InputObject $obj -NotePropertyName $name -NotePropertyValue $val -Force
                }
                $projected += $obj
            }
            $filtered = $projected
        } elseif ($spec.Directives.ContainsKey('groupBy')) {
            # Ensure Group column appears by default if grouping
            $projected = @()
            foreach ($row in $filtered) {
                $obj = [pscustomobject]@{ Group = $row.Group }
                foreach ($p in $row.PSObject.Properties) { if ($p.Name -ne 'Group') { Add-Member -InputObject $obj -NotePropertyName $p.Name -NotePropertyValue $p.Value -Force } }
                $projected += $obj
            }
            $filtered = $projected
        }

        # Limit
        if ($spec.Directives.ContainsKey('limit')) {
            $n = [int]$spec.Directives['limit']
            $filtered = @($filtered | Select-Object -First $n)
        }

        return @{
            Success = $true
            Data = ,$filtered
            Metadata = @{
                EstimatedRows = $spec.EstimatedRows
                ActualRows = @($filtered).Count
                Strategy = $spec.OptimizationStrategy
                Cached = $false
            }
        }
    }

    [object] ExecuteLegacyQuery([PmcEnhancedQuerySpec]$spec) {
        # Legacy query path removed - all queries go through AST now
        Write-PmcDebug -Level 1 -Category 'Query' -Message 'Legacy query execution attempted but disabled'
        return @()
        return @{ Success = $true; Data = @(); Metadata = @{ EstimatedRows = 0; ActualRows = 0; Strategy = 'none'; Cached = $false } }
    }

    [hashtable] GetExecutionStats() {
        $cacheStats = $this._cache.GetStats()
        $avgDuration = if ($this._executionStats.QueriesExecuted -gt 0) {
            [Math]::Round($this._executionStats.TotalDuration / $this._executionStats.QueriesExecuted, 2)
        } else { 0 }

        return @{
            QueriesExecuted = $this._executionStats.QueriesExecuted
            AverageDuration = $avgDuration
            TotalDuration = $this._executionStats.TotalDuration
            CacheStats = $cacheStats
        }
    }

    [void] ClearCache() {
        $this._cache.Clear()
    }

    [void] ResetStats() {
        $this._executionStats = @{
            QueriesExecuted = 0
            TotalDuration = 0
            CacheHits = 0
            CacheMisses = 0
        }
        $this._cache.Clear()
    }
}

# Global instances
$Script:PmcEnhancedQueryParser = $null
$Script:PmcEnhancedQueryExecutor = $null

function Initialize-PmcEnhancedQueryEngine {
    if ($Script:PmcEnhancedQueryParser) {
        Write-Warning "PMC Enhanced Query Engine already initialized"
        return
    }

    $Script:PmcEnhancedQueryParser = [PmcEnhancedQueryParser]::new()
    $Script:PmcEnhancedQueryExecutor = [PmcEnhancedQueryExecutor]::new()

    Write-PmcDebug -Level 2 -Category 'EnhancedQuery' -Message "Enhanced query engine initialized"
}

function Invoke-PmcEnhancedQuery {
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$Tokens,

        [switch]$NoCache
    )

    if (-not $Script:PmcEnhancedQueryParser) {
        Initialize-PmcEnhancedQueryEngine
    }

    $spec = $Script:PmcEnhancedQueryParser.ParseQuery($Tokens)

    if (-not $spec.IsValid()) {
        Write-PmcStyled -Style 'Error' -Text "Query validation failed: $($spec.ValidationErrors -join '; ')"
        return @{ Success = $false; Errors = $spec.ValidationErrors }
    }

    if ($NoCache) {
        $Script:PmcEnhancedQueryExecutor.ClearCache()
    }

    return $Script:PmcEnhancedQueryExecutor.ExecuteQuery($spec)
}

function Get-PmcQueryPerformanceStats {
    if (-not $Script:PmcEnhancedQueryExecutor) {
        Write-Host "Enhanced query engine not initialized"
        return
    }

    $stats = $Script:PmcEnhancedQueryExecutor.GetExecutionStats()

    Write-Host "PMC Query Performance Statistics" -ForegroundColor Green
    Write-Host "===============================" -ForegroundColor Green
    Write-Host "Queries Executed: $($stats.QueriesExecuted)"
    Write-Host "Average Duration: $($stats.AverageDuration) ms"
    Write-Host "Total Duration: $($stats.TotalDuration) ms"
    Write-Host ""
    Write-Host "Cache Performance:" -ForegroundColor Yellow
    Write-Host "Cache Size: $($stats.CacheStats.Size)"
    Write-Host "Cache Hit Rate: $($stats.CacheStats.HitRate)%"
    Write-Host "Cache Hits: $($stats.CacheStats.Hits)"
    Write-Host "Cache Misses: $($stats.CacheStats.Misses)"
    Write-Host "Cache Evictions: $($stats.CacheStats.Evictions)"
}

Export-ModuleMember -Function Initialize-PmcEnhancedQueryEngine, Invoke-PmcEnhancedQuery, Get-PmcQueryPerformanceStats


# END FILE: ./module/Pmc.Strict/Core/EnhancedQueryEngine.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/Core/Handlers.ps1
# SIZE: 5.17 KB
# MODIFIED: 2025-09-21 18:38:40
# ================================================================================

Set-StrictMode -Version Latest

class PmcHandlerDescriptor {
    [string] $Domain
    [string] $Action
    [scriptblock] $Validate
    [scriptblock] $Execute
    PmcHandlerDescriptor([string]$d,[string]$a,[scriptblock]$v,[scriptblock]$e){ $this.Domain=$d; $this.Action=$a; $this.Validate=$v; $this.Execute=$e }
}

$Script:PmcHandlers = @{}

function Register-PmcHandler {
    param([Parameter(Mandatory=$true)][string]$Domain,[Parameter(Mandatory=$true)][string]$Action,[Parameter(Mandatory=$true)][scriptblock]$Execute,[scriptblock]$Validate)
    $key = ("{0}:{1}" -f $Domain.ToLower(), $Action.ToLower())
    $Script:PmcHandlers[$key] = [PmcHandlerDescriptor]::new($Domain,$Action,$Validate,$Execute)
}

function Get-PmcHandler {
    param([string]$Domain,[string]$Action)
    $key = ("{0}:{1}" -f $Domain.ToLower(), $Action.ToLower())
    if ($Script:PmcHandlers.ContainsKey($key)) { return $Script:PmcHandlers[$key] }
    return $null
}

function Initialize-PmcHandlers {
    # Auto-register all domain/action functions from CommandMap as handlers
    try {
        if ($Script:PmcCommandMap) {
            foreach ($domain in $Script:PmcCommandMap.Keys) {
                foreach ($action in $Script:PmcCommandMap[$domain].Keys) {
                    $fnName = [string]$Script:PmcCommandMap[$domain][$action]
                    $d = $domain; $a = $action; $f = $fnName
                    # Build an execute block that prefers services for key domains
                    $exec = {
                        param([PmcCommandContext]$Context)
                        try {
                            $domainLower = "$d".ToLower()
                            if ($domainLower -eq 'task') {
                                $svc = $null; try { $svc = Get-PmcService -Name 'TaskService' } catch {}
                                if ($svc) {
                                    switch ("$a".ToLower()) {
                                        'add' { return (Add-PmcTask -Context $Context) }
                                        'list' { return (Get-PmcTaskList) }
                                    }
                                }
                            }
                            elseif ($domainLower -eq 'project') {
                                $psvc = $null; try { $psvc = Get-PmcService -Name 'ProjectService' } catch {}
                                if ($psvc) {
                                    switch ("$a".ToLower()) {
                                        'add' { return (Add-PmcProject -Context $Context) }
                                        'list' { return (Get-PmcProjectList) }
                                    }
                                }
                            }
                            elseif ($domainLower -eq 'time') {
                                $tsvc = $null; try { $tsvc = Get-PmcService -Name 'TimeService' } catch {}
                                if ($tsvc) {
                                    switch ("$a".ToLower()) {
                                        'log' { return (Add-PmcTimeEntry -Context $Context) }
                                        'list' { return (Get-PmcTimeList) }
                                        'report' { return (Get-PmcTimeReport) }
                                    }
                                }
                            }
                            elseif ($domainLower -eq 'timer') {
                                $timersvc = $null; try { $timersvc = Get-PmcService -Name 'TimerService' } catch {}
                                if ($timersvc) {
                                    switch ("$a".ToLower()) {
                                        'start' { return (Start-PmcTimer) }
                                        'stop' { return (Stop-PmcTimer) }
                                        'status' { return (Get-PmcTimerStatus) }
                                    }
                                }
                            }
                            elseif ($domainLower -eq 'focus') {
                                $fsvc = $null; try { $fsvc = Get-PmcService -Name 'FocusService' } catch {}
                                if ($fsvc) {
                                    switch ("$a".ToLower()) {
                                        'set' { return (Set-PmcFocus -Context $Context) }
                                        'clear' { return (Clear-PmcFocus) }
                                        'status' { return (Get-PmcFocusStatus) }
                                    }
                                }
                            }

                            if (Get-Command -Name $f -ErrorAction SilentlyContinue) { & $f -Context $Context }
                            else { Write-PmcStyled -Style 'Warning' -Text ("Handler not implemented: {0} {1}" -f $d,$a) }
                        } catch { Write-PmcStyled -Style 'Error' -Text (("{0} {1} failed: {2}" -f $d,$a,$_)) }
                    }
                    Register-PmcHandler -Domain $d -Action $a -Execute $exec
                }
            }
        }
    } catch { Write-PmcDebug -Level 1 -Category 'Handlers' -Message "Auto-registration failed: $_" }
}

Export-ModuleMember -Function Register-PmcHandler, Get-PmcHandler, Initialize-PmcHandlers


# END FILE: ./module/Pmc.Strict/Core/Handlers.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/Core/PerformanceOptimizer.ps1
# SIZE: 17.59 KB
# MODIFIED: 2025-09-21 15:26:08
# ================================================================================

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

# END FILE: ./module/Pmc.Strict/Core/PerformanceOptimizer.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/Core/QueryDiscovery.ps1
# SIZE: 5.52 KB
# MODIFIED: 2025-09-21 16:56:36
# ================================================================================

Set-StrictMode -Version Latest

function Show-PmcQueryFields {
    [CmdletBinding()] param(
        [Parameter(Mandatory=$true)][ValidateSet('task','project','timelog')][string]$Domain,
        [switch]$Json
    )
    $schemas = Get-PmcFieldSchemasForDomain -Domain $Domain
    $rows = @()
    foreach ($name in ($schemas.Keys | Sort-Object)) {
        $s = $schemas[$name]
        $type = if ($s.PSObject.Properties['Type']) { [string]$s.Type } else { 'string' }
        $ops = @(':','=','>','<','>=','<=','~','exists')
        if ($type -eq 'date' -or $name -eq 'due') { $ops += @('today','tomorrow','overdue','+N','eow','eom') }
        $rows += [pscustomobject]@{
            Field = $name
            Type = $type
            Operators = ($ops -join ', ')
            Example = switch ($name) {
                'project' { '@inbox' }
                'tags'    { '#urgent' }
                'priority'{ 'p<=2' }
                'due'     { 'due:today' }
                default   { "$name:value" }
            }
        }
    }
    if ($Json) { $rows | ConvertTo-Json -Depth 5; return }
    Show-PmcDataGrid -Domains @("$Domain-fields") -Columns @{
        Field=@{Header='Field';Width=18}
        Type=@{Header='Type';Width=10}
        Operators=@{Header='Operators';Width=40}
        Example=@{Header='Example';Width=20}
    } -Data $rows -Title ("Fields — {0}" -f $Domain)
}

function Show-PmcQueryColumns {
    [CmdletBinding()] param(
        [Parameter(Mandatory=$true)][ValidateSet('task','project','timelog')][string]$Domain,
        [switch]$Json
    )
    $defaults = Get-PmcDefaultColumns -DataType $Domain
    $schemas = Get-PmcFieldSchemasForDomain -Domain $Domain
    $rows = @()
    # Default columns first
    foreach ($k in $defaults.Keys) {
        $cfg = $defaults[$k]
        $rows += [pscustomobject]@{
            Column=$k; Header=[string]$cfg.Header; Default=$true; Sortable=$true; Editable=($cfg.Editable -eq $true)
        }
    }
    # Other fields available
    foreach ($name in $schemas.Keys) {
        if ($rows | Where-Object { $_.Column -eq $name }) { continue }
        $s = $schemas[$name]
        $rows += [pscustomobject]@{
            Column=$name; Header=$name; Default=$false; Sortable=$true; Editable=($s.Editable -eq $true)
        }
    }
    if ($Json) { $rows | ConvertTo-Json -Depth 5; return }
    Show-PmcDataGrid -Domains @("$Domain-columns") -Columns @{
        Column=@{Header='Column';Width=18}
        Header=@{Header='Header';Width=20}
        Default=@{Header='Default';Width=8}
        Sortable=@{Header='Sortable';Width=8}
        Editable=@{Header='Editable';Width=8}
    } -Data $rows -Title ("Columns — {0}" -f $Domain)
}

function Show-PmcQueryValues {
    [CmdletBinding()] param(
        [Parameter(Mandatory=$true)][ValidateSet('task','project','timelog')][string]$Domain,
        [Parameter(Mandatory=$true)][string]$Field,
        [int]$Top=50,
        [string]$StartsWith,
        [switch]$Json
    )
    $data = switch ($Domain) {
        'task'    { if (Get-Command Get-PmcTasksData -ErrorAction SilentlyContinue)    { Get-PmcTasksData }    else { @() } }
        'project' { if (Get-Command Get-PmcProjectsData -ErrorAction SilentlyContinue) { Get-PmcProjectsData } else { @() } }
        'timelog' { if (Get-Command Get-PmcTimeLogsData -ErrorAction SilentlyContinue) { Get-PmcTimeLogsData } else { @() } }
    }
    $values = @()
    foreach ($row in $data) {
        if ($null -eq $row) { continue }
        if ($row.PSObject.Properties[$Field]) {
            $v = $row."$Field"
            if ($v -is [System.Collections.IEnumerable] -and -not ($v -is [string])) {
                foreach ($x in $v) { if ($null -ne $x) { $values += [string]$x } }
            } else {
                if ($null -ne $v) { $values += [string]$v }
            }
        }
    }
    $distinct = @($values | Where-Object { $_ -and $_.Trim() -ne '' } | Select-Object -Unique | Sort-Object)
    if ($StartsWith) { $distinct = @($distinct | Where-Object { $_.ToLower().StartsWith($StartsWith.ToLower()) }) }
    $distinct = @($distinct | Select-Object -First $Top)
    $rows = @(); foreach ($v in $distinct) { $rows += [pscustomobject]@{ Value=$v } }
    if ($Json) { $rows | ConvertTo-Json -Depth 5; return }
    Show-PmcDataGrid -Domains @("$Domain-values") -Columns @{ Value=@{Header='Value';Width=50} } -Data $rows -Title ("Values — {0}.{1}" -f $Domain,$Field)
}

function Show-PmcQueryDirectives {
    [CmdletBinding()] param(
        [ValidateSet('task','project','timelog')][string]$Domain,
        [switch]$Json
    )
    $rows = @()
    $rows += [pscustomobject]@{ Directive='cols';      Syntax='cols:id,text,project';         Notes='Select display columns' }
    $rows += [pscustomobject]@{ Directive='sort';      Syntax='sort:due+ | sort:priority-';  Notes='Field+ asc, Field- desc' }
    $rows += [pscustomobject]@{ Directive='group';     Syntax='group:project';                Notes='Grouping (display; planned)' }
    $rows += [pscustomobject]@{ Directive='limit';     Syntax='limit:50';                     Notes='Max items' }
    $rows += [pscustomobject]@{ Directive='shorthand'; Syntax='@project #tag p<=2 due:today'; Notes='Helpers for common filters' }
    if ($Json) { $rows | ConvertTo-Json -Depth 5; return }
    Show-PmcDataGrid -Domains @('query-directives') -Columns @{
        Directive=@{Header='Directive';Width=12}
        Syntax=@{Header='Syntax';Width=40}
        Notes=@{Header='Notes';Width=40}
    } -Data $rows -Title 'Query Directives'
}

Export-ModuleMember -Function Show-PmcQueryFields, Show-PmcQueryColumns, Show-PmcQueryValues, Show-PmcQueryDirectives



# END FILE: ./module/Pmc.Strict/Core/QueryDiscovery.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/Core/Security.ps1
# SIZE: 1.28 KB
# MODIFIED: 2025-09-21 17:17:49
# ================================================================================

Set-StrictMode -Version Latest

class PmcSecureFileManager {
    [bool] ValidatePath([string]$Path, [string]$Operation) {
        try { return (Test-PmcPathSafety -Path $Path -Operation $Operation) } catch { return $false }
    }

    [bool] ValidateContent([string]$Content, [string]$Type) {
        try { return (Test-PmcInputSafety -Input $Content -InputType $Type) } catch { return $true }
    }

    [void] WriteFile([string]$Path, [string]$Content) {
        if (-not $this.ValidatePath($Path,'write')) { throw "Path not allowed: $Path" }
        if (-not $this.ValidateContent($Content,'json')) { throw "Content failed safety validation" }
        Invoke-PmcSecureFileOperation -Path $Path -Operation 'write' -Content $Content
    }

    [string] ReadFile([string]$Path) {
        if (-not $this.ValidatePath($Path,'read')) { throw "Path not allowed: $Path" }
        return (Get-Content -Path $Path -Raw -Encoding UTF8)
    }
}

function Get-PmcSecureFileManager {
    if (-not $Script:PmcSecureFileManager) { $Script:PmcSecureFileManager = [PmcSecureFileManager]::new() }
    return $Script:PmcSecureFileManager
}

function Sanitize-PmcCommandInput { param([string]$Text) return (Protect-PmcUserInput -Input $Text) }

Export-ModuleMember -Function Get-PmcSecureFileManager, Sanitize-PmcCommandInput



# END FILE: ./module/Pmc.Strict/Core/Security.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/Core/StateManager.ps1
# SIZE: 13.75 KB
# MODIFIED: 2025-09-22 07:11:55
# ================================================================================

# PMC Secure State Management System
# Replaces scattered script variables with thread-safe, validated state access

Set-StrictMode -Version Latest

# Security policy for state access validation
class PmcSecurityPolicy {
    [hashtable] $AllowedSections = @{
        'Config' = @('Read', 'Write')
        'Security' = @('Read', 'Write')
        'Debug' = @('Read', 'Write')
        'Display' = @('Read', 'Write')
        'Interactive' = @('Read', 'Write')
        'Commands' = @('Read', 'Write')
        'Tasks' = @('Read', 'Write')
        'Projects' = @('Read', 'Write')
        'Time' = @('Read', 'Write')
        'Help' = @('Read', 'Write')
        'UndoRedo' = @('Read', 'Write')
        'Cache' = @('Read', 'Write')
        'Focus' = @('Read', 'Write')
        'Analytics' = @('Read', 'Write')
    }

    [void] ValidateStateAccess([string]$section, [string]$key, [string]$operation) {
        if ([string]::IsNullOrWhiteSpace($section)) {
            throw "State section cannot be null or empty"
        }

        if ([string]::IsNullOrWhiteSpace($key)) {
            throw "State key cannot be null or empty"
        }

        if (-not $this.AllowedSections.ContainsKey($section)) {
            throw "Access denied: Section '$section' is not allowed"
        }

        if ($operation -notin $this.AllowedSections[$section]) {
            throw "Access denied: Operation '$operation' not allowed on section '$section'"
        }

        # Additional security checks
        if ($key.Contains('..') -or $key.Contains('/') -or $key.Contains('\')) {
            throw "Security violation: Invalid characters in state key '$key'"
        }
    }

    [void] ValidateStateValue([object]$value, [string]$section = '') {
        if ($null -eq $value) {
            return  # null values are allowed
        }

        # Allow scriptblocks only for config providers
        if ($value -is [scriptblock]) {
            if ($section -ne 'Config') {
                throw "Security violation: Cannot store scriptblocks in state (except Config section)"
            }
        }

        # Check for potentially dangerous string content
        if ($value -is [string]) {
            $dangerousPatterns = @(
                'Invoke-Expression', 'iex', 'cmd.exe', 'powershell.exe',
                'Start-Process', 'New-Object.*ComObject'
            )
            foreach ($pattern in $dangerousPatterns) {
                if ($value -match $pattern) {
                    throw "Security violation: Potentially dangerous content detected in state value"
                }
            }
        }
    }
}

# Thread-safe, secure state manager
class PmcSecureStateManager {
    hidden [hashtable] $_state = @{}
    hidden [System.Threading.ReaderWriterLockSlim] $_lock
    hidden [PmcSecurityPolicy] $_security
    hidden [bool] $_initialized = $false

    PmcSecureStateManager() {
        $this._lock = [System.Threading.ReaderWriterLockSlim]::new()
        $this._security = [PmcSecurityPolicy]::new()
        $this.InitializeDefaultSections()
        $this._initialized = $true
    }

    [void] InitializeDefaultSections() {
        # Initialize all allowed sections with empty hashtables
        foreach ($section in $this._security.AllowedSections.Keys) {
            $this._state[$section] = @{}
        }
    }

    [object] GetState([string]$section, [string]$key) {
        if (-not $this._initialized) {
            throw "State manager not initialized"
        }

        $this._security.ValidateStateAccess($section, $key, 'Read')

        $this._lock.EnterReadLock()
        try {
            if (-not $this._state.ContainsKey($section)) {
                return $null
            }
            return $this._state[$section][$key]
        } finally {
            $this._lock.ExitReadLock()
        }
    }

    [void] SetState([string]$section, [string]$key, [object]$value) {
        if (-not $this._initialized) {
            throw "State manager not initialized"
        }

        $this._security.ValidateStateAccess($section, $key, 'Write')
        $this._security.ValidateStateValue($value, $section)

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

    [hashtable] GetSection([string]$section) {
        if (-not $this._initialized) {
            throw "State manager not initialized"
        }

        $this._security.ValidateStateAccess($section, 'SectionAccess', 'Read')

        $this._lock.EnterReadLock()
        try {
            if (-not $this._state.ContainsKey($section)) {
                return @{}
            }
            # Return a copy to prevent external modification
            return $this._state[$section].Clone()
        } finally {
            $this._lock.ExitReadLock()
        }
    }

    [void] SetSection([string]$section, [hashtable]$data) {
        if (-not $this._initialized) {
            throw "State manager not initialized"
        }

        $this._security.ValidateStateAccess($section, 'SectionAccess', 'Write')

        # Validate all values in the section
        foreach ($key in $data.Keys) {
            $this._security.ValidateStateValue($data[$key], $section)
        }

        $this._lock.EnterWriteLock()
        try {
            $this._state[$section] = $data.Clone()
        } finally {
            $this._lock.ExitWriteLock()
        }
    }

    [void] ClearSection([string]$section) {
        if (-not $this._initialized) {
            throw "State manager not initialized"
        }

        $this._security.ValidateStateAccess($section, 'SectionAccess', 'Write')

        $this._lock.EnterWriteLock()
        try {
            $this._state[$section] = @{}
        } finally {
            $this._lock.ExitWriteLock()
        }
    }

    [hashtable] GetSnapshot() {
        if (-not $this._initialized) {
            throw "State manager not initialized"
        }

        $this._lock.EnterReadLock()
        try {
            $snapshot = @{}
            foreach ($section in $this._state.Keys) {
                $snapshot[$section] = $this._state[$section].Clone()
            }
            return $snapshot
        } finally {
            $this._lock.ExitReadLock()
        }
    }

    [void] Dispose() {
        if ($this._lock) {
            $this._lock.Dispose()
        }
    }
}

# Global instance (will be initialized by main module)
$Script:SecureStateManager = $null

# Backward-compatible API functions that route through secure manager
function Get-PmcState {
    param(
        [Parameter(Mandatory=$true)][string]$Section,
        [Parameter(Mandatory=$true)][string]$Key
    )

    if ($null -eq $Script:SecureStateManager) {
        throw "PMC State Manager not initialized. Call Initialize-PmcSecureState first."
    }

    return $Script:SecureStateManager.GetState($Section, $Key)
}

function Set-PmcState {
    param(
        [Parameter(Mandatory=$true)][string]$Section,
        [Parameter(Mandatory=$true)][string]$Key,
        [Parameter(Mandatory=$true)][object]$Value
    )

    if ($null -eq $Script:SecureStateManager) {
        throw "PMC State Manager not initialized. Call Initialize-PmcSecureState first."
    }

    $Script:SecureStateManager.SetState($Section, $Key, $Value)
}

function Update-PmcStateSection {
    param(
        [Parameter(Mandatory=$true)][string]$Section,
        [Parameter(Mandatory=$true)][hashtable]$Updates
    )

    if ($null -eq $Script:SecureStateManager) {
        throw "PMC State Manager not initialized. Call Initialize-PmcSecureState first."
    }

    # Get current section data
    $currentData = $Script:SecureStateManager.GetSection($Section)

    # Apply updates
    foreach ($key in $Updates.Keys) {
        $currentData[$key] = $Updates[$key]
    }

    # Set updated section
    $Script:SecureStateManager.SetSection($Section, $currentData)
}

function Initialize-PmcSecureState {
    [CmdletBinding()]
    param()

    if ($Script:SecureStateManager) {
        Write-Warning "PMC State Manager already initialized"
        return
    }

    try {
        $Script:SecureStateManager = [PmcSecureStateManager]::new()
        Write-Verbose "PMC Secure State Manager initialized successfully"

        # Migrate existing state if it exists (backward compatibility)
        if (Get-Variable -Name 'PmcGlobalState' -Scope Script -ErrorAction SilentlyContinue) {
            Write-Verbose "Migrating existing state to secure manager"
            $oldState = Get-Variable -Name 'PmcGlobalState' -Scope Script -ValueOnly

            foreach ($section in $oldState.Keys) {
                if ($oldState[$section] -is [hashtable]) {
                    $Script:SecureStateManager.SetSection($section, $oldState[$section])
                }
            }

            # Remove old state variable
            Remove-Variable -Name 'PmcGlobalState' -Scope Script -Force -ErrorAction SilentlyContinue
        }

    } catch {
        Write-Error "Failed to initialize PMC Secure State Manager: $_"
        throw
    }
}

function Reset-PmcSecureState {
    [CmdletBinding()]
    param()

    if ($Script:SecureStateManager) {
        $Script:SecureStateManager.Dispose()
        $Script:SecureStateManager = $null
    }

    Initialize-PmcSecureState
}

# Additional helper functions for common state operations
function Get-PmcStateSection {
    param([Parameter(Mandatory=$true)][string]$Section)

    if ($null -eq $Script:SecureStateManager) {
        throw "PMC State Manager not initialized"
    }

    return $Script:SecureStateManager.GetSection($Section)
}

function Set-PmcStateSection {
    param(
        [Parameter(Mandatory=$true)][string]$Section,
        [Parameter(Mandatory=$true)][hashtable]$Data
    )

    if ($null -eq $Script:SecureStateManager) {
        throw "PMC State Manager not initialized"
    }

    $Script:SecureStateManager.SetSection($Section, $Data)
}

function Clear-PmcStateSection {
    param([Parameter(Mandatory=$true)][string]$Section)

    if ($null -eq $Script:SecureStateManager) {
        throw "PMC State Manager not initialized"
    }

    $Script:SecureStateManager.ClearSection($Section)
}

function Get-PmcStateSnapshot {
    if ($null -eq $Script:SecureStateManager) {
        throw "PMC State Manager not initialized"
    }

    return $Script:SecureStateManager.GetSnapshot()
}

# Legacy compatibility functions (convenience wrappers)
function Get-PmcDebugState {
    $section = Get-PmcStateSection -Section 'Debug'
    # Convert hashtable to object with properties for backward compatibility
    $state = [PSCustomObject]@{
        Level = if ($section.ContainsKey('Level')) { $section['Level'] } else { 0 }
        LogPath = if ($section.ContainsKey('LogPath')) { $section['LogPath'] } else { 'debug.log' }
        SessionId = if ($section.ContainsKey('SessionId')) { $section['SessionId'] } else { [System.Guid]::NewGuid().ToString() }
        Enabled = if ($section.ContainsKey('Enabled')) { $section['Enabled'] } else { $false }
    }
    return $state
}

function Get-PmcHelpState {
    return Get-PmcState -Section 'HelpUI' -Key 'HelpState'
}

function Get-PmcCommandCategories {
    return Get-PmcState -Section 'HelpUI' -Key 'CommandCategories'
}

function Set-PmcDebugState {
    param([hashtable]$State)
    Set-PmcStateSection -Section 'Debug' -Data $State
}

function Set-PmcHelpState {
    param([object]$State)
    Set-PmcState -Section 'HelpUI' -Key 'HelpState' -Value $State
}

function Set-PmcCommandCategories {
    param([object]$Categories)
    Set-PmcState -Section 'HelpUI' -Key 'CommandCategories' -Value $Categories
}

# Config provider functions (missing from refactor)
function Get-PmcConfigProviders {
    $section = Get-PmcStateSection -Section 'Config'
    return @{
        Get = if ($section.ContainsKey('ProviderGet')) { $section['ProviderGet'] } else { { @{} } }
        Set = if ($section.ContainsKey('ProviderSet')) { $section['ProviderSet'] } else { $null }
    }
}

function Set-PmcConfigProviders {
    param([scriptblock]$Get, [scriptblock]$Set)
    Set-PmcState -Section 'Config' -Key 'ProviderGet' -Value $Get
    if ($Set) { Set-PmcState -Section 'Config' -Key 'ProviderSet' -Value $Set }
}

# Security state functions (missing from refactor)
function Get-PmcSecurityState {
    $section = Get-PmcStateSection -Section 'Security'
    # Convert hashtable to object with properties for backward compatibility
    $state = [PSCustomObject]@{
        InputValidationEnabled = if ($section.ContainsKey('InputValidationEnabled')) { $section['InputValidationEnabled'] } else { $true }
        PathWhitelistEnabled = if ($section.ContainsKey('PathWhitelistEnabled')) { $section['PathWhitelistEnabled'] } else { $true }
        ResourceLimitsEnabled = if ($section.ContainsKey('ResourceLimitsEnabled')) { $section['ResourceLimitsEnabled'] } else { $true }
        AllowedWritePaths = if ($section.ContainsKey('AllowedWritePaths')) { $section['AllowedWritePaths'] } else { @() }
        MaxFileSize = if ($section.ContainsKey('MaxFileSize')) { $section['MaxFileSize'] } else { 100MB }
        MaxMemoryUsage = if ($section.ContainsKey('MaxMemoryUsage')) { $section['MaxMemoryUsage'] } else { 500MB }
    }
    return $state
}

# Simple wrapper function to satisfy missing calls
function Update-PmcStateSection {
    param([string]$Section, [hashtable]$Data)
    if ($Data) {
        Set-PmcStateSection -Section $Section -Data $Data
    }
}

# Export functions for use by other modules
Export-ModuleMember -Function Get-PmcState, Set-PmcState, Update-PmcStateSection, Initialize-PmcSecureState, Reset-PmcSecureState, Get-PmcStateSection, Set-PmcStateSection, Clear-PmcStateSection, Get-PmcStateSnapshot, Get-PmcDebugState, Set-PmcDebugState, Get-PmcHelpState, Set-PmcHelpState, Get-PmcCommandCategories, Set-PmcCommandCategories, Get-PmcConfigProviders, Set-PmcConfigProviders, Get-PmcSecurityState

# END FILE: ./module/Pmc.Strict/Core/StateManager.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/Core/UnifiedInitializer.ps1
# SIZE: 18.31 KB
# MODIFIED: 2025-09-22 11:59:49
# ================================================================================

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


# END FILE: ./module/Pmc.Strict/Core/UnifiedInitializer.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/Services/FocusService.ps1
# SIZE: 1.51 KB
# MODIFIED: 2025-09-21 18:38:23
# ================================================================================

Set-StrictMode -Version Latest

class PmcFocusService {
    hidden $_state
    PmcFocusService([object]$stateManager) { $this._state = $stateManager }

    [string] SetFocus([string]$Project) {
        Set-PmcState -Section 'Focus' -Key 'Project' -Value $Project
        return $Project
    }

    [void] ClearFocus() { Set-PmcState -Section 'Focus' -Key 'Project' -Value $null }

    [pscustomobject] GetStatus() {
        $p = Get-PmcState -Section 'Focus' -Key 'Project'
        return [pscustomobject]@{ Project=$p; Active=([string]::IsNullOrWhiteSpace($p) -eq $false) }
    }
}

function New-PmcFocusService { param($StateManager) return [PmcFocusService]::new($StateManager) }

function Set-PmcFocus { param([PmcCommandContext]$Context)
    $svc = Get-PmcService -Name 'FocusService'; if (-not $svc) { throw 'FocusService not available' }
    $p = if (@($Context.FreeText).Count -gt 0) { ($Context.FreeText -join ' ') } else { [string]$Context.Args['project'] }
    $v = $svc.SetFocus($p)
    Write-PmcStyled -Style 'Success' -Text ("🎯 Focus set: {0}" -f $v)
    return $v
}

function Clear-PmcFocus { $svc = Get-PmcService -Name 'FocusService'; if (-not $svc) { throw 'FocusService not available' }; $svc.ClearFocus(); Write-PmcStyled -Style 'Warning' -Text '🎯 Focus cleared' }
function Get-PmcFocusStatus { $svc = Get-PmcService -Name 'FocusService'; if (-not $svc) { throw 'FocusService not available' }; return $svc.GetStatus() }

Export-ModuleMember -Function Set-PmcFocus, Clear-PmcFocus, Get-PmcFocusStatus, New-PmcFocusService



# END FILE: ./module/Pmc.Strict/Services/FocusService.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/Services/LegacyCompat.ps1
# SIZE: 17.08 KB
# MODIFIED: 2025-09-24 16:36:10
# ================================================================================

Set-StrictMode -Version Latest

# Helper: get and save data
function _Get-PmcData() { return Get-PmcDataAlias }
function _Save-PmcData($data,$action='') { Save-StrictData $data $action }

# Legacy compatibility wrapper
function Get-PmcData() { return Get-PmcDataAlias }

# Helper: resolve task ids from context
function _Resolve-TaskIds {
    param([PmcCommandContext]$Context)
    $ids = @()
    if ($Context.Args.ContainsKey('ids')) { $ids = @($Context.Args['ids']) }
    elseif (@($Context.FreeText).Count -gt 0) {
        $t0 = [string]$Context.FreeText[0]
        if ($t0 -match '^[0-9,\-]+$') {
            $ids = @($t0 -split ',' | ForEach-Object { if ($_ -match '^\d+$') { [int]$_ } })
        } elseif ($t0 -match '^\d+$') { $ids = @([int]$t0) }
    }
    return ,$ids
}

# Task domain wrappers
function Show-PmcTask { param([PmcCommandContext]$Context)
    $ids = _Resolve-TaskIds $Context
    $data = _Get-PmcData
    $rows = if ($ids.Count -gt 0) { @($data.tasks | Where-Object { $_.id -in $ids }) } else { @() }
    Show-PmcDataGrid -Domains @('task') -Columns (Get-PmcDefaultColumns -DataType 'task') -Data $rows -Title 'Task'
}

function Set-PmcTask { param([PmcCommandContext]$Context)
    $ids = _Resolve-TaskIds $Context
    if ($ids.Count -eq 0) { Write-PmcStyled -Style 'Warning' -Text 'No task id provided'; return }
    $data = _Get-PmcData
    foreach ($t in @($data.tasks | Where-Object { $_.id -in $ids })) {
        foreach ($k in $Context.Args.Keys) { if ($k -ne 'ids') { try { $t | Add-Member -NotePropertyName $k -NotePropertyValue $Context.Args[$k] -Force } catch {} } }
    }
    _Save-PmcData $data 'task:update'
    Write-PmcStyled -Style 'Success' -Text ("✓ Updated {0} task(s)" -f $ids.Count)
}

function Complete-PmcTask { param([PmcCommandContext]$Context)
    $ids = _Resolve-TaskIds $Context; if ($ids.Count -eq 0) { return }
    $data = _Get-PmcData
    foreach ($t in @($data.tasks | Where-Object { $_.id -in $ids })) { $t.status = 'completed'; $t.completed = (Get-Date).ToString('o') }
    _Save-PmcData $data 'task:done'
    Write-PmcStyled -Style 'Success' -Text ("✓ Completed {0} task(s)" -f $ids.Count)
}

function Remove-PmcTask { param([PmcCommandContext]$Context)
    $ids = _Resolve-TaskIds $Context; if ($ids.Count -eq 0) { return }
    $data = _Get-PmcData
    $data.tasks = @($data.tasks | Where-Object { $_.id -notin $ids })
    _Save-PmcData $data 'task:remove'
    Write-PmcStyled -Style 'Warning' -Text ("✗ Removed {0} task(s)" -f $ids.Count)
}

function Move-PmcTask { param([PmcCommandContext]$Context)
    $ids = _Resolve-TaskIds $Context; $proj = [string]$Context.Args['project']
    if ($ids.Count -eq 0 -or [string]::IsNullOrWhiteSpace($proj)) { return }
    $data = _Get-PmcData
    foreach ($t in @($data.tasks | Where-Object { $_.id -in $ids })) { $t.project = $proj }
    _Save-PmcData $data 'task:move'
    Write-PmcStyled -Style 'Success' -Text ("✓ Moved {0} task(s) to @{1}" -f $ids.Count,$proj)
}

function Set-PmcTaskPostponed { param([PmcCommandContext]$Context)
    $ids = _Resolve-TaskIds $Context; $days = 1; if ($Context.Args['days']) { $days = [int]$Context.Args['days'] }
    $data = _Get-PmcData
    foreach ($t in @($data.tasks | Where-Object { $_.id -in $ids })) {
        $d = if ($t.due) { [datetime]$t.due } else { (Get-Date) }
        $t.due = $d.AddDays($days).ToString('yyyy-MM-dd')
    }
    _Save-PmcData $data 'task:postpone'
    Write-PmcStyled -Style 'Success' -Text ("✓ Postponed {0} task(s) by {1} day(s)" -f $ids.Count,$days)
}

function Copy-PmcTask { param([PmcCommandContext]$Context)
    $ids = _Resolve-TaskIds $Context; if ($ids.Count -eq 0) { return }
    $data = _Get-PmcData
    foreach ($t in @($data.tasks | Where-Object { $_.id -in $ids })) {
        $clone = $t.PSObject.Copy(); $clone.id = ($data.tasks | ForEach-Object { $_.id } | Measure-Object -Maximum).Maximum + 1
        $data.tasks += $clone
    }
    _Save-PmcData $data 'task:copy'
    Write-PmcStyled -Style 'Success' -Text ("✓ Duplicated {0} task(s)" -f $ids.Count)
}

function Add-PmcTaskNote { param([PmcCommandContext]$Context)
    $ids = _Resolve-TaskIds $Context; $note = ($Context.FreeText | Select-Object -Skip 1) -join ' '
    $data = _Get-PmcData
    foreach ($t in @($data.tasks | Where-Object { $_.id -in $ids })) { if (-not $t.notes) { $t.notes=@() }; $t.notes += $note }
    _Save-PmcData $data 'task:note'
}

function Edit-PmcTask { param([PmcCommandContext]$Context)
    $ids = _Resolve-TaskIds $Context; $text = ($Context.FreeText | Select-Object -Skip 1) -join ' '
    $data = _Get-PmcData
    foreach ($t in @($data.tasks | Where-Object { $_.id -in $ids })) { $t.text = $text }
    _Save-PmcData $data 'task:edit'
}

function Find-PmcTask { param([PmcCommandContext]$Context)
    $needle = ($Context.FreeText -join ' ')
    $res = Invoke-PmcEnhancedQuery -Tokens @('tasks',$needle)
    Show-PmcDataGrid -Domains @('task') -Columns (Get-PmcDefaultColumns -DataType 'task') -Data $res.Data -Title "Search: $needle"
}

function Set-PmcTaskPriority { param([PmcCommandContext]$Context)
    $ids = _Resolve-TaskIds $Context; $p = [string]$Context.Args['priority']
    $data = _Get-PmcData
    foreach ($t in @($data.tasks | Where-Object { $_.id -in $ids })) { $t.priority = $p }
    _Save-PmcData $data 'task:priority'
}

function Show-PmcAgenda { $res = Invoke-PmcEnhancedQuery -Tokens @('tasks','due:today'); Show-PmcDataGrid -Domains @('task') -Columns (Get-PmcDefaultColumns -DataType 'task') -Data $res.Data -Title 'Agenda' }
function Show-PmcWeekTasksInteractive { $res = Invoke-PmcEnhancedQuery -Tokens @('tasks','due:+7'); Show-PmcDataGrid -Domains @('task') -Columns (Get-PmcDefaultColumns -DataType 'task') -Data $res.Data -Title 'Week' -Interactive }
function Show-PmcMonthTasksInteractive { $res = Invoke-PmcEnhancedQuery -Tokens @('tasks','due:eom'); Show-PmcDataGrid -Domains @('task') -Columns (Get-PmcDefaultColumns -DataType 'task') -Data $res.Data -Title 'Month' -Interactive }

function Show-PmcTodayTasksInteractive { $res = Invoke-PmcEnhancedQuery -Tokens @('tasks','due:today'); Show-PmcDataGrid -Domains @('task') -Columns (Get-PmcDefaultColumns -DataType 'task') -Data $res.Data -Title 'Today' -Interactive }
function Show-PmcOverdueTasksInteractive { $res = Invoke-PmcEnhancedQuery -Tokens @('tasks','overdue'); Show-PmcDataGrid -Domains @('task') -Columns (Get-PmcDefaultColumns -DataType 'task') -Data $res.Data -Title 'Overdue' -Interactive }
function Show-PmcProjectsInteractive { $res = Invoke-PmcEnhancedQuery -Tokens @('projects'); Show-PmcDataGrid -Domains @('project') -Columns (Get-PmcDefaultColumns -DataType 'project') -Data $res.Data -Title 'Projects' -Interactive }
function Show-PmcAllTasksInteractive { $res = Invoke-PmcEnhancedQuery -Tokens @('tasks'); Show-PmcDataGrid -Domains @('task') -Columns (Get-PmcDefaultColumns -DataType 'task') -Data $res.Data -Title 'All Tasks' -Interactive }

# Project domain wrappers
function Show-PmcProject { param([PmcCommandContext]$Context)
    $name = if (@($Context.FreeText).Count -gt 0) { [string]$Context.FreeText[0] } else { '' }
    $data = _Get-PmcData
    $rows = @($data.projects | Where-Object { $_.name -eq $name })
    Show-PmcDataGrid -Domains @('project') -Columns (Get-PmcDefaultColumns -DataType 'project') -Data $rows -Title 'Project'
}

function Set-PmcProject { param([PmcCommandContext]$Context)
    $name = if (@($Context.FreeText).Count -gt 0) { [string]$Context.FreeText[0] } else { '' }
    $data = _Get-PmcData
    $p = @($data.projects | Where-Object { $_.name -eq $name }) | Select-Object -First 1
    if (-not $p) { Write-PmcStyled -Style 'Warning' -Text "Project not found"; return }
    foreach ($k in $Context.Args.Keys) { try { $p | Add-Member -NotePropertyName $k -NotePropertyValue $Context.Args[$k] -Force } catch {} }
    _Save-PmcData $data 'project:update'
    Write-PmcStyled -Style 'Success' -Text ("✓ Updated project: {0}" -f $name)
}

function Rename-PmcProject { param([PmcCommandContext]$Context)
    if (@($Context.FreeText).Count -lt 2) { return }
    $old = [string]$Context.FreeText[0]; $new = [string]$Context.FreeText[1]
    $data = _Get-PmcData
    $p = @($data.projects | Where-Object { $_.name -eq $old }) | Select-Object -First 1
    if ($p) { $p.name = $new; _Save-PmcData $data 'project:rename'; Write-PmcStyled -Style 'Success' -Text ("✓ Renamed project to {0}" -f $new) }
}

function Remove-PmcProject { param([PmcCommandContext]$Context)
    $name = if (@($Context.FreeText).Count -gt 0) { [string]$Context.FreeText[0] } else { '' }
    $data = _Get-PmcData
    $data.projects = @($data.projects | Where-Object { $_.name -ne $name })
    _Save-PmcData $data 'project:remove'
}

function Set-PmcProjectArchived { param([PmcCommandContext]$Context)
    $name = if (@($Context.FreeText).Count -gt 0) { [string]$Context.FreeText[0] } else { '' }
    $data = _Get-PmcData
    $p = @($data.projects | Where-Object { $_.name -eq $name }) | Select-Object -First 1
    if ($p) { $p.status = 'archived'; _Save-PmcData $data 'project:archive' }
}

function Set-PmcProjectFields { param([PmcCommandContext]$Context) Set-PmcProject -Context $Context }
function Show-PmcProjectFields { $schemas = Get-PmcFieldSchemasForDomain -Domain 'project'; $rows=@(); foreach ($k in $schemas.Keys) { $rows += [pscustomobject]@{ Field=$k; Type=$schemas[$k].Type } }; Show-PmcDataGrid -Domains @('project-fields') -Columns @{ Field=@{Header='Field';Width=24}; Type=@{Header='Type';Width=12} } -Data $rows -Title 'Project Fields' }
function Get-PmcProjectStats { $data=_Get-PmcData; $rows=@(); foreach ($p in $data.projects) { $c = @($data.tasks | Where-Object { $_.project -eq $p.name }).Count; $rows += [pscustomobject]@{ Project=$p.name; Tasks=$c } }; return $rows }
function Show-PmcProjectInfo { $data=_Get-PmcData; $rows=@(); foreach ($p in $data.projects) { $rows += [pscustomobject]@{ Project=$p.name; Status=$p.status; Created=$p.created } }; Show-PmcDataGrid -Domains @('project-info') -Columns @{ Project=@{Header='Project';Width=24}; Status=@{Header='Status';Width=10}; Created=@{Header='Created';Width=24} } -Data $rows -Title 'Projects Info' }
function Get-PmcRecentProjects { $data=_Get-PmcData; return @($data.projects | Sort-Object { try { [datetime]$_.created } catch { Get-Date } } -Descending | Select-Object -First 10) }

# Time domain wrappers (edit/delete)
function Edit-PmcTimeEntry { param([PmcCommandContext]$Context)
    $id = 0; if ($Context.Args['id']) { $id = [int]$Context.Args['id'] } elseif (@($Context.FreeText).Count -gt 0) { $id = [int]$Context.FreeText[0] }
    $data=_Get-PmcData; $e=@($data.timelogs | Where-Object { $_.id -eq $id }) | Select-Object -First 1
    if ($e) { foreach ($k in $Context.Args.Keys) { if ($k -ne 'id') { $e | Add-Member -NotePropertyName $k -NotePropertyValue $Context.Args[$k] -Force } } ; _Save-PmcData $data 'time:edit' }
}
function Remove-PmcTimeEntry { param([PmcCommandContext]$Context)
    $id = 0; if ($Context.Args['id']) { $id = [int]$Context.Args['id'] } elseif (@($Context.FreeText).Count -gt 0) { $id = [int]$Context.FreeText[0] }
    $data=_Get-PmcData; $data.timelogs = @($data.timelogs | Where-Object { $_.id -ne $id }); _Save-PmcData $data 'time:remove'
}

# Alias wrappers
function Add-PmcAlias { param([PmcCommandContext]$Context)
    $name = if (@($Context.FreeText).Count -gt 0) { [string]$Context.FreeText[0] } else { '' }
    $value = if (@($Context.FreeText).Count -gt 1) { ($Context.FreeText | Select-Object -Skip 1) -join ' ' } else { '' }
    $data=_Get-PmcData; if (-not $data.aliases) { $data | Add-Member -NotePropertyName aliases -NotePropertyValue @{} -Force }
    $data.aliases[$name] = $value; _Save-PmcData $data 'alias:add'
}
function Remove-PmcAlias { param([PmcCommandContext]$Context)
    $name = if (@($Context.FreeText).Count -gt 0) { [string]$Context.FreeText[0] } else { '' }
    $data=_Get-PmcData; if ($data.aliases) { $data.aliases.Remove($name) | Out-Null }; _Save-PmcData $data 'alias:remove'
}
function Get-PmcAliasList { $data=_Get-PmcData; $rows=@(); if ($data.aliases) { foreach ($k in $data.aliases.Keys) { $rows += [pscustomobject]@{ Name=$k; Value=$data.aliases[$k] } } }; Show-PmcDataGrid -Domains @('aliases') -Columns @{ Name=@{Header='Name';Width=20}; Value=@{Header='Value';Width=60} } -Data $rows -Title 'Aliases' }

# System wrappers
function New-PmcBackup { $file = (Get-Item (Get-PmcTaskFilePath)).FullName; $dest = "$file.bak_$(Get-Date -Format yyyyMMdd_HHmmss)"; Copy-Item $file $dest -Force; Write-PmcStyled -Style 'Success' -Text ("Backup created: {0}" -f (Split-Path $dest -Leaf)) }
function Clear-PmcCompletedTasks { $data=_Get-PmcData; $before=@($data.tasks).Count; $data.tasks=@($data.tasks | Where-Object { $_.status -ne 'completed' }); _Save-PmcData $data 'system:clean'; Write-PmcStyled -Style 'Warning' -Text ("Removed {0} completed task(s)" -f ($before-@($data.tasks).Count)) }
function Invoke-PmcUndo { Write-PmcStyled -Style 'Warning' -Text 'Undo not available (legacy in-memory undo removed)'; }
function Invoke-PmcRedo { Write-PmcStyled -Style 'Warning' -Text 'Redo not available (legacy in-memory redo removed)'; }

# Import/Export and Excel/XFlow stubs
function Import-PmcTasks { Write-PmcStyled -Style 'Warning' -Text 'Import is temporarily unavailable in enhanced mode' }
function Export-PmcTasks { Write-PmcStyled -Style 'Warning' -Text 'Export is temporarily unavailable in enhanced mode' }
function Import-PmcExcelData { Write-PmcStyled -Style 'Warning' -Text 'Excel integration is temporarily unavailable in enhanced mode' }
function Show-PmcExcelPreview { Write-PmcStyled -Style 'Warning' -Text 'Excel preview unavailable' }
function Get-PmcLatestExcelFile { return $null }
function Set-PmcXFlowSourcePathInteractive { Write-PmcStyled -Style 'Warning' -Text 'XFlow disabled' }
function Set-PmcXFlowDestPathInteractive { Write-PmcStyled -Style 'Warning' -Text 'XFlow disabled' }
function Show-PmcXFlowPreview { Write-PmcStyled -Style 'Warning' -Text 'XFlow disabled' }
function Invoke-PmcXFlowRun { Write-PmcStyled -Style 'Warning' -Text 'XFlow disabled' }
function Export-PmcXFlowText { Write-PmcStyled -Style 'Warning' -Text 'XFlow disabled' }
function Import-PmcXFlowMappingsFromFile { Write-PmcStyled -Style 'Warning' -Text 'XFlow disabled' }
function Set-PmcXFlowLatestFromFile { Write-PmcStyled -Style 'Warning' -Text 'XFlow disabled' }
function Show-PmcXFlowConfig { Write-PmcStyled -Style 'Warning' -Text 'XFlow disabled' }

# Show commands
function Show-PmcCommands { $rows=@(); foreach ($d in $Script:PmcCommandMap.Keys) { foreach ($a in $Script:PmcCommandMap[$d].Keys) { $rows += [pscustomobject]@{ Domain=$d; Action=$a; Handler=$Script:PmcCommandMap[$d][$a] } } }; Show-PmcDataGrid -Domains @('commands') -Columns @{ Domain=@{Header='Domain';Width=14}; Action=@{Header='Action';Width=16}; Handler=@{Header='Handler';Width=36} } -Data $rows -Title 'Commands' }

# Missing CommandMap functions
function Add-PmcRecurringTask { param($Context); Write-PmcStyled -Style 'Warning' -Text 'Recurring tasks not yet implemented' }
function Get-PmcActivityList { param($Context); Write-PmcStyled -Style 'Warning' -Text 'Activity list not yet implemented' }

# Missing Shortcut functions
function Invoke-PmcShortcutNumber { param($Context); Write-PmcStyled -Style 'Warning' -Text 'Shortcut numbers not yet implemented' }
function Show-PmcWeekTasks { param($Context); Show-PmcWeekTasksInteractive -Context $Context }
function Get-PmcVelocity { param($Context); Write-PmcStyled -Style 'Warning' -Text 'Velocity metrics not yet implemented' }
function Get-PmcStats { param($Context); Write-PmcStyled -Style 'Warning' -Text 'Stats not yet implemented' }
function Start-PmcReview { param($Context); Write-PmcStyled -Style 'Warning' -Text 'Review system not yet implemented' }
function Show-PmcBurndown { param($Context); Write-PmcStyled -Style 'Warning' -Text 'Burndown chart not yet implemented' }
function Show-PmcNextTasks { param($Context); Show-PmcNextActions -Context $Context }
function Show-PmcMonthTasks { param($Context); Show-PmcMonthTasksInteractive -Context $Context }

# Export all legacy compatibility functions
Export-ModuleMember -Function Get-PmcData, Show-PmcTask, Set-PmcTask, Complete-PmcTask, Remove-PmcTask, Move-PmcTask, Set-PmcTaskPostponed, Copy-PmcTask, Add-PmcTaskNote, Edit-PmcTask, Find-PmcTask, Set-PmcTaskPriority, Show-PmcAgenda, Show-PmcWeekTasksInteractive, Show-PmcMonthTasksInteractive, Show-PmcTodayTasksInteractive, Show-PmcOverdueTasksInteractive, Show-PmcProjectsInteractive, Show-PmcAllTasksInteractive, Show-PmcProject, Set-PmcProject, Rename-PmcProject, Remove-PmcProject, Set-PmcProjectArchived, Set-PmcProjectFields, Show-PmcProjectFields, Get-PmcProjectStats, Show-PmcProjectInfo, Get-PmcRecentProjects, Edit-PmcTimeEntry, Remove-PmcTimeEntry, Add-PmcAlias, Remove-PmcAlias, Get-PmcAliasList, New-PmcBackup, Clear-PmcCompletedTasks, Invoke-PmcUndo, Invoke-PmcRedo, Import-PmcTasks, Export-PmcTasks, Import-PmcExcelData, Show-PmcExcelPreview, Get-PmcLatestExcelFile, Set-PmcXFlowSourcePathInteractive, Set-PmcXFlowDestPathInteractive, Show-PmcXFlowPreview, Invoke-PmcXFlowRun, Export-PmcXFlowText, Import-PmcXFlowMappingsFromFile, Set-PmcXFlowLatestFromFile, Show-PmcXFlowConfig, Show-PmcCommands, Add-PmcRecurringTask, Get-PmcActivityList, Invoke-PmcShortcutNumber, Show-PmcWeekTasks, Get-PmcVelocity, Get-PmcStats, Start-PmcReview, Show-PmcBurndown, Show-PmcNextTasks, Show-PmcMonthTasks



# END FILE: ./module/Pmc.Strict/Services/LegacyCompat.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/Services/ProjectService.ps1
# SIZE: 1.92 KB
# MODIFIED: 2025-09-21 18:33:31
# ================================================================================

Set-StrictMode -Version Latest

class PmcProjectService {
    hidden $_state
    hidden $_logger

    PmcProjectService([object]$stateManager, [object]$logger) {
        $this._state = $stateManager
        $this._logger = $logger
    }

    [pscustomobject] AddProject([string]$Name, [string]$Description) {
        $data = Get-PmcData
        if (-not $data.projects) { $data.projects = @() }

        # If exists, update description
        $existing = @($data.projects | Where-Object { $_.name -eq $Name })
        if ($existing.Count -gt 0) {
            $existing[0].description = $Description
            Save-PmcData $data
            return $existing[0]
        }

        $proj = [pscustomobject]@{
            name = $Name
            description = $Description
            status = 'active'
            created = (Get-Date).ToString('o')
        }
        $data.projects += $proj
        Save-PmcData $data
        return $proj
    }

    [object[]] GetProjects() {
        $data = Get-PmcData
        return ,@($data.projects)
    }
}

function New-PmcProjectService { param($StateManager,$Logger) return [PmcProjectService]::new($StateManager,$Logger) }

function Add-PmcProject {
    param([PmcCommandContext]$Context)
    $svc = Get-PmcService -Name 'ProjectService'
    if (-not $svc) { throw 'ProjectService not available' }
    $name = ''
    $desc = ''
    if (@($Context.FreeText).Count -gt 0) { $name = [string]$Context.FreeText[0] }
    if (@($Context.FreeText).Count -gt 1) { $desc = ($Context.FreeText | Select-Object -Skip 1) -join ' ' }
    $res = $svc.AddProject($name,$desc)
    Write-PmcStyled -Style 'Success' -Text ("✓ Project ensured: {0}" -f $res.name)
    return $res
}

function Get-PmcProjectList {
    $svc = Get-PmcService -Name 'ProjectService'
    if (-not $svc) { throw 'ProjectService not available' }
    return $svc.GetProjects()
}

Export-ModuleMember -Function Add-PmcProject, Get-PmcProjectList, New-PmcProjectService



# END FILE: ./module/Pmc.Strict/Services/ProjectService.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/Services/ServiceRegistry.ps1
# SIZE: 3.14 KB
# MODIFIED: 2025-09-21 18:38:30
# ================================================================================

Set-StrictMode -Version Latest

$Script:PmcServices = @{}

function Register-PmcService {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][object]$Instance
    )
    $Script:PmcServices[$Name] = $Instance
}

function Get-PmcService {
    param([Parameter(Mandatory=$true)][string]$Name)
    if ($Script:PmcServices.ContainsKey($Name)) { return $Script:PmcServices[$Name] }
    return $null
}

function Initialize-PmcServices {
    # Create core services and register them
    try {
        # TaskService
        if (Get-Command -Name Get-PmcSecureFileManager -ErrorAction SilentlyContinue) {
            $state = $Script:SecureStateManager
            $logger = $null
            if (Test-Path "$PSScriptRoot/TaskService.ps1") { . "$PSScriptRoot/TaskService.ps1" }
            if (Get-Command -Name New-PmcTaskService -ErrorAction SilentlyContinue) {
                $svc = New-PmcTaskService -StateManager $state -Logger $logger
                Register-PmcService -Name 'TaskService' -Instance $svc
            }
        }
    } catch {
        Write-PmcDebug -Level 1 -Category 'ServiceRegistry' -Message "TaskService initialization failed: $_"
    }

    try { # ProjectService
        $state = $Script:SecureStateManager; $logger = $null
        if (Test-Path "$PSScriptRoot/ProjectService.ps1") { . "$PSScriptRoot/ProjectService.ps1" }
        if (Get-Command -Name New-PmcProjectService -ErrorAction SilentlyContinue) { Register-PmcService -Name 'ProjectService' -Instance (New-PmcProjectService -StateManager $state -Logger $logger) }
    } catch { Write-PmcDebug -Level 1 -Category 'ServiceRegistry' -Message "ProjectService initialization failed: $_" }

    try { # TimeService
        $state = $Script:SecureStateManager; $logger = $null
        if (Test-Path "$PSScriptRoot/TimeService.ps1") { . "$PSScriptRoot/TimeService.ps1" }
        if (Get-Command -Name New-PmcTimeService -ErrorAction SilentlyContinue) { Register-PmcService -Name 'TimeService' -Instance (New-PmcTimeService -StateManager $state -Logger $logger) }
    } catch { Write-PmcDebug -Level 1 -Category 'ServiceRegistry' -Message "TimeService initialization failed: $_" }

    try { # TimerService
        $state = $Script:SecureStateManager
        if (Test-Path "$PSScriptRoot/TimerService.ps1") { . "$PSScriptRoot/TimerService.ps1" }
        if (Get-Command -Name New-PmcTimerService -ErrorAction SilentlyContinue) { Register-PmcService -Name 'TimerService' -Instance (New-PmcTimerService -StateManager $state) }
    } catch { Write-PmcDebug -Level 1 -Category 'ServiceRegistry' -Message "TimerService initialization failed: $_" }

    try { # FocusService
        $state = $Script:SecureStateManager
        if (Test-Path "$PSScriptRoot/FocusService.ps1") { . "$PSScriptRoot/FocusService.ps1" }
        if (Get-Command -Name New-PmcFocusService -ErrorAction SilentlyContinue) { Register-PmcService -Name 'FocusService' -Instance (New-PmcFocusService -StateManager $state) }
    } catch { Write-PmcDebug -Level 1 -Category 'ServiceRegistry' -Message "FocusService initialization failed: $_" }
}

Export-ModuleMember -Function Register-PmcService, Get-PmcService, Initialize-PmcServices


# END FILE: ./module/Pmc.Strict/Services/ServiceRegistry.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/Services/TaskService.ps1
# SIZE: 2.39 KB
# MODIFIED: 2025-09-21 18:33:23
# ================================================================================

Set-StrictMode -Version Latest

class PmcTaskService {
    hidden $_state
    hidden $_logger

    PmcTaskService([object]$stateManager, [object]$logger) {
        $this._state = $stateManager
        $this._logger = $logger
    }

    [pscustomobject] AddTask([string]$Text, [string]$Project, [string]$Priority, [string]$Due, [string[]]$Tags) {
        $data = Get-PmcData
        if (-not $data.tasks) { $data.tasks = @() }

        $new = [pscustomobject]@{
            id       = $this.GetNextId($data)
            text     = $Text
            project  = $Project
            priority = if ($Priority) { $Priority } else { 'p2' }
            due      = $Due
            tags     = if ($Tags) { $Tags } else { @() }
            status   = 'pending'
            created  = (Get-Date).ToString('o')
        }

        $data.tasks += $new
        Save-PmcData $data
        return $new
    }

    [object[]] GetTasks() {
        $data = Get-PmcData
        return ,@($data.tasks)
    }

    hidden [int] GetNextId($data) {
        try {
            $ids = @($data.tasks | ForEach-Object { try { [int]$_.id } catch { 0 } })
            $max = ($ids | Measure-Object -Maximum).Maximum
            return ([int]$max + 1)
        } catch { return 1 }
    }
}

function New-PmcTaskService { param($StateManager,$Logger) return [PmcTaskService]::new($StateManager,$Logger) }

# Public function wrappers (compat with CommandMap)
function Add-PmcTask {
    param([PmcCommandContext]$Context)
    $svc = Get-PmcService -Name 'TaskService'
    if (-not $svc) { throw 'TaskService not available' }
    $text = ($Context.FreeText -join ' ').Trim()
    $proj = if ($Context.Args.ContainsKey('project')) { [string]$Context.Args['project'] } else { $null }
    $prio = if ($Context.Args.ContainsKey('priority')) { [string]$Context.Args['priority'] } else { $null }
    $due  = if ($Context.Args.ContainsKey('due')) { [string]$Context.Args['due'] } else { $null }
    $tags = if ($Context.Args.ContainsKey('tags')) { @($Context.Args['tags']) } else { @() }
    $res = $svc.AddTask($text,$proj,$prio,$due,$tags)
    Write-PmcStyled -Style 'Success' -Text ("✓ Task added: [{0}] {1}" -f $res.id,$res.text)
    return $res
}

function Get-PmcTaskList {
    $svc = Get-PmcService -Name 'TaskService'
    if (-not $svc) { throw 'TaskService not available' }
    return $svc.GetTasks()
}

Export-ModuleMember -Function Add-PmcTask, Get-PmcTaskList, New-PmcTaskService



# END FILE: ./module/Pmc.Strict/Services/TaskService.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/Services/TimerService.ps1
# SIZE: 2.02 KB
# MODIFIED: 2025-09-21 18:38:17
# ================================================================================

Set-StrictMode -Version Latest

class PmcTimerService {
    hidden $_state
    PmcTimerService([object]$stateManager) { $this._state = $stateManager }

    [void] Start() {
        Set-PmcState -Section 'Time' -Key 'TimerStart' -Value (Get-Date).ToString('o')
        Set-PmcState -Section 'Time' -Key 'TimerRunning' -Value $true
    }

    [pscustomobject] Stop() {
        $startStr = Get-PmcState -Section 'Time' -Key 'TimerStart'
        $running = Get-PmcState -Section 'Time' -Key 'TimerRunning'
        if (-not $running -or -not $startStr) { return [pscustomobject]@{ Running=$false; Elapsed=0 } }
        $start = [datetime]$startStr
        $elapsed = ([datetime]::Now - $start).TotalHours
        Set-PmcState -Section 'Time' -Key 'TimerRunning' -Value $false
        return [pscustomobject]@{ Running=$false; Elapsed=[Math]::Round($elapsed,2) }
    }

    [pscustomobject] Status() {
        $startStr = Get-PmcState -Section 'Time' -Key 'TimerStart'
        $running = Get-PmcState -Section 'Time' -Key 'TimerRunning'
        $elapsed = 0
        if ($running -and $startStr) { $elapsed = ([datetime]::Now - [datetime]$startStr).TotalHours }
        return [pscustomobject]@{ Running=($running -eq $true); Started=$startStr; Elapsed=[Math]::Round($elapsed,2) }
    }
}

function New-PmcTimerService { param($StateManager) return [PmcTimerService]::new($StateManager) }

function Start-PmcTimer { $svc = Get-PmcService -Name 'TimerService'; if (-not $svc) { throw 'TimerService not available' }; $svc.Start(); Write-PmcStyled -Style 'Success' -Text '⏱ Timer started' }
function Stop-PmcTimer { $svc = Get-PmcService -Name 'TimerService'; if (-not $svc) { throw 'TimerService not available' }; $r=$svc.Stop(); Write-PmcStyled -Style 'Success' -Text ("⏹ Timer stopped ({0}h)" -f $r.Elapsed); return $r }
function Get-PmcTimerStatus { $svc = Get-PmcService -Name 'TimerService'; if (-not $svc) { throw 'TimerService not available' }; return $svc.Status() }

Export-ModuleMember -Function Start-PmcTimer, Stop-PmcTimer, Get-PmcTimerStatus, New-PmcTimerService



# END FILE: ./module/Pmc.Strict/Services/TimerService.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/Services/TimeService.ps1
# SIZE: 3.36 KB
# MODIFIED: 2025-09-21 18:38:05
# ================================================================================

Set-StrictMode -Version Latest

class PmcTimeService {
    hidden $_state
    hidden $_logger

    PmcTimeService([object]$stateManager, [object]$logger) {
        $this._state = $stateManager
        $this._logger = $logger
    }

    [pscustomobject] AddTimeEntry([int]$TaskId, [string]$Project, [string]$Duration, [string]$Description) {
        $data = Get-PmcData
        if (-not $data.timelogs) { $data.timelogs = @() }

        $hours = 0.0
        if ($Duration) {
            if ($Duration -match '^(\d+(?:\.\d+)?)h$') { $hours = [double]$matches[1] }
            elseif ($Duration -match '^(\d+)m$') { $hours = [double]$matches[1] / 60.0 }
            elseif ($Duration -match '^(\d+)h(\d+)m$') { $hours = [double]$matches[1] + ([double]$matches[2]/60.0) }
            elseif ($Duration -match '^\d+(?:\.\d+)?$') { $hours = [double]$Duration }
        }

        $entry = [pscustomobject]@{
            id = $this.GetNextId($data)
            task = $TaskId
            project = $Project
            start = (Get-Date).ToString('o')
            end = (Get-Date).ToString('o')
            duration = $hours
            description = $Description
        }
        $data.timelogs += $entry
        Save-PmcData $data
        return $entry
    }

    [object[]] GetTimeList() { $data = Get-PmcData; return ,@($data.timelogs) }

    [pscustomobject] GetReport([datetime]$From,[datetime]$To) {
        $items = $this.GetTimeList() | Where-Object { try { $d=[datetime]$_.start; $d -ge $From -and $d -le $To } catch { $false } }
        $total = ($items | Measure-Object duration -Sum).Sum
        return [pscustomobject]@{ From=$From; To=$To; Hours=$total; Entries=$items }
    }

    hidden [int] GetNextId($data) {
        try { $ids = @($data.timelogs | ForEach-Object { try { [int]$_.id } catch { 0 } }); $max = ($ids | Measure-Object -Maximum).Maximum; return ([int]$max + 1) } catch { return 1 }
    }
}

function New-PmcTimeService { param($StateManager,$Logger) return [PmcTimeService]::new($StateManager,$Logger) }

function Add-PmcTimeEntry { param([PmcCommandContext]$Context)
    $svc = Get-PmcService -Name 'TimeService'; if (-not $svc) { throw 'TimeService not available' }
    $taskId = 0; if ($Context.Args.ContainsKey('task')) { $taskId = [int]$Context.Args['task'] } elseif (@($Context.FreeText).Count -gt 0 -and $Context.FreeText[0] -match '^\d+$') { $taskId = [int]$Context.FreeText[0] }
    $proj = if ($Context.Args.ContainsKey('project')) { [string]$Context.Args['project'] } else { $null }
    $dur  = if ($Context.Args.ContainsKey('duration')) { [string]$Context.Args['duration'] } else { $null }
    $desc = if (@($Context.FreeText).Count -gt 1) { ($Context.FreeText | Select-Object -Skip 1) -join ' ' } else { '' }
    $res = $svc.AddTimeEntry($taskId,$proj,$dur,$desc)
    Write-PmcStyled -Style 'Success' -Text ("✓ Time logged: {0}h on task {1}" -f $res.duration,$res.task)
    return $res
}

function Get-PmcTimeList { $svc = Get-PmcService -Name 'TimeService'; if (-not $svc) { throw 'TimeService not available' }; return $svc.GetTimeList() }

function Get-PmcTimeReport {
    param([datetime]$From=(Get-Date).Date.AddDays(-7), [datetime]$To=(Get-Date))
    $svc = Get-PmcService -Name 'TimeService'; if (-not $svc) { throw 'TimeService not available' }
    return $svc.GetReport($From,$To)
}

Export-ModuleMember -Function Add-PmcTimeEntry, Get-PmcTimeList, Get-PmcTimeReport, New-PmcTimeService



# END FILE: ./module/Pmc.Strict/Services/TimeService.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/Aliases.ps1
# SIZE: 5.59 KB
# MODIFIED: 2025-09-24 05:32:30
# ================================================================================

# User alias system: alias, alias add, alias remove; show aliases

function Get-PmcAliasTable {
    $data = Get-PmcDataAlias
    if (-not (Pmc-HasProp $data 'aliases') -or -not $data.aliases) { $data.aliases = @{} }
    # Normalize to hashtable if JSON loaded as PSCustomObject
    if ($data.aliases -is [pscustomobject]) {
        $ht = @{}
        foreach ($p in $data.aliases.PSObject.Properties) { $ht[$p.Name] = $p.Value }
        $data.aliases = $ht
    }
    # Seed helpful defaults if empty
    try {
        $keyCount = 0
        if ($data.aliases -is [hashtable]) { $keyCount = @($data.aliases.Keys).Count }
        elseif ($data.aliases.PSObject -and $data.aliases.PSObject.Properties) { $keyCount = @($data.aliases.PSObject.Properties.Name).Count }
    } catch { $keyCount = 0 }
    if ($keyCount -eq 0) {
        $data.aliases['projects'] = 'view projects'
    }
    return $data.aliases
}

function Save-PmcAliases($aliases) {
    $data = Get-PmcDataAlias
    $data.aliases = $aliases
    Save-StrictData $data 'alias update'
}

function Get-PmcAliasList {
    param([PmcCommandContext]$Context)
    $aliases = Get-PmcAliasTable
    Write-PmcStyled -Style 'Header' -Text "\nALIASES"
    Write-PmcStyled -Style 'Border' -Text "────────"
    $rows = @()
    if ($aliases -is [hashtable]) {
        foreach ($entry in $aliases.GetEnumerator()) {
            $rows += @{ alias = [string]$entry.Key; expands = [string]$entry.Value }
        }
    } elseif ($aliases -is [pscustomobject]) {
        foreach ($p in $aliases.PSObject.Properties) {
            $rows += @{ alias = [string]$p.Name; expands = [string]$p.Value }
        }
    }
    if (@($rows).Count -eq 0) { Write-PmcStyled -Style 'Warning' -Text 'No aliases defined'; return }
    $rows = $rows | Sort-Object alias

    # Convert to universal display format
    $columns = @{
        "alias" = @{ Header = "Alias"; Width = 16; Alignment = "Left"; Editable = $false }
        "expands" = @{ Header = "Expands To"; Width = 48; Alignment = "Left"; Editable = $false }
    }

    # Convert rows to PSCustomObject format
    $dataObjects = @()
    foreach ($row in $rows) {
        $obj = New-Object PSCustomObject
        foreach ($key in $row.Keys) {
            $obj | Add-Member -NotePropertyName $key -NotePropertyValue $row[$key]
        }
        $dataObjects += $obj
    }

    Show-PmcCustomGrid -Domain "config" -Columns $columns -Data $dataObjects -Title "User Aliases"
}

function Add-PmcAlias {
    param(
        $Context,
        [string]$Name,
        [string]$Value
    )

    # Handle both PmcCommandContext and direct parameter calls
    if ($Context -and -not $Name -and -not $Value) {
        # Called with Context parameter
        if ($Context.PSObject.Properties['FreeText']) {
            $text = ($Context.FreeText -join ' ').Trim()
            if (-not $text -or -not ($text -match '^(\S+)\s+(.+)$')) {
                Write-PmcStyled -Style 'Warning' -Text "Usage: alias add <name> <expansion...>"
                return
            }
            $name = $matches[1]; $expansion = $matches[2]
        } else {
            Write-PmcStyled -Style 'Error' -Text "Invalid context parameter"
            return
        }
    } elseif ($Name -and $Value) {
        # Called with direct parameters
        $name = $Name; $expansion = $Value
    } else {
        Write-PmcStyled -Style 'Warning' -Text "Usage: Add-PmcAlias -Name <name> -Value <expansion> or alias add <name> <expansion>"
        return
    }

    $aliases = Get-PmcAliasTable
    $aliases[$name] = $expansion
    Save-PmcAliases $aliases
    Write-PmcStyled -Style 'Success' -Text ("Added alias '{0}' = {1}" -f $name, $expansion)
}

function Remove-PmcAlias {
    param([PmcCommandContext]$Context)
    $name = ($Context.FreeText -join ' ').Trim()
    if ([string]::IsNullOrWhiteSpace($name)) { Write-PmcStyled -Style 'Warning' -Text "Usage: alias remove <name>"; return }
    $aliases = Get-PmcAliasTable
    if (-not $aliases.ContainsKey($name)) { Write-PmcStyled -Style 'Error' -Text ("Alias '{0}' not found" -f $name); return }
    $aliases.Remove($name) | Out-Null
    Save-PmcAliases $aliases
    Write-PmcStyled -Style 'Success' -Text ("Removed alias '{0}'" -f $name)
}

function Expand-PmcUserAliases {
    param([string]$Buffer)
    try {
        $aliases = Get-PmcAliasTable
        if (-not $aliases) { return $Buffer }
        # Normalize alias keys safely
        $keys = @()
        if ($aliases -is [hashtable]) { $keys = @($aliases.Keys) }
        elseif ($aliases.PSObject -and $aliases.PSObject.Properties) { $keys = @($aliases.PSObject.Properties.Name) }
        if (@($keys).Count -eq 0) { return $Buffer }
        $tokens = ConvertTo-PmcTokens $Buffer
        if ($tokens.Count -eq 0) { return $Buffer }
        $first = $tokens[0]
        $hasKey = $false
        $expansion = $null
        if ($aliases -is [hashtable]) { $hasKey = $aliases.ContainsKey($first); if ($hasKey) { $expansion = [string]$aliases[$first] } }
        elseif ($aliases.PSObject) { try { $expansion = [string]($aliases.$first); $hasKey = -not [string]::IsNullOrEmpty($expansion) } catch {
            # Property access failed - alias does not exist
        } }
        if ($hasKey -and $expansion) {
            # Replace first token with its expansion
            $rest = ''
            if ($tokens.Count -gt 1) { $rest = ' ' + ($tokens[1..($tokens.Count-1)] -join ' ') }
            return ($expansion + $rest)
        }
    } catch {
        # Alias expansion failed - return original buffer
    }
    return $Buffer
}

Export-ModuleMember -Function Get-PmcAliasTable, Save-PmcAliases, Get-PmcAliasList, Add-PmcAlias, Remove-PmcAlias, Expand-PmcUserAliases


# END FILE: ./module/Pmc.Strict/src/Aliases.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/Analytics.ps1
# SIZE: 5.19 KB
# MODIFIED: 2025-09-24 05:29:58
# ================================================================================

# Analytics and Insights: stats, burndown, velocity

function Get-PmcStatistics {
    param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category "Analytics" -Message "Starting stats"

    $data = Get-PmcDataAlias
    $now = Get-Date
    $d7 = $now.Date.AddDays(-7)
    $d30 = $now.Date.AddDays(-30)

    $pending = @($data.tasks | Where-Object { $_.status -eq 'pending' }).Count
    $completed = @($data.tasks | Where-Object { $_.status -eq 'completed' }).Count
    $completed7 = @($data.tasks | Where-Object { $_.completed -and ([datetime]$_.completed) -ge $d7 }).Count
    $added7 = @($data.tasks | Where-Object { $_.created -and ([datetime]$_.created) -ge $d7 }).Count

    $logs7 = @($data.timelogs | Where-Object { $_.date -and ([datetime]$_.date) -ge $d7 })
    $minutes7 = ($logs7 | Measure-Object minutes -Sum).Sum
    $hours7 = [Math]::Round(($minutes7/60),2)

    $rows = @(
        @{ metric='Pending tasks'; value=$pending },
        @{ metric='Completed (all)'; value=$completed },
        @{ metric='Completed (7d)'; value=$completed7 },
        @{ metric='Added (7d)'; value=$added7 },
        @{ metric='Hours logged (7d)'; value=$hours7 }
    )
    # Convert to universal display format
    $columns = @{
        "metric" = @{ Header = "Metric"; Width = 26; Alignment = "Left"; Editable = $false }
        "value" = @{ Header = "Value"; Width = 10; Alignment = "Right"; Editable = $false }
    }

    # Convert rows to PSCustomObject format
    $dataObjects = @()
    foreach ($row in $rows) {
        $obj = New-Object PSCustomObject
        foreach ($key in $row.Keys) {
            $obj | Add-Member -NotePropertyName $key -NotePropertyValue $row[$key]
        }
        $dataObjects += $obj
    }

    Show-PmcCustomGrid -Domain "stats" -Columns $columns -Data $dataObjects -Title 'STATS'

    Write-PmcDebug -Level 2 -Category "Analytics" -Message "Stats completed" -Data @{ Pending=$pending; Completed7=$completed7; Hours7=$hours7 }
}

function Show-PmcBurndownChart {
    param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category "Analytics" -Message "Starting burndown"

    $data = Get-PmcDataAlias
    $today = (Get-Date).Date
    $horizon = 7
    $rows = @()

    for ($i=0; $i -lt $horizon; $i++) {
        $day = $today.AddDays($i)
        $remaining = @($data.tasks | Where-Object {
            try {
                $_.status -eq 'pending' -and (
                    (-not $_.due) -or ([datetime]$_.due) -ge $day
                )
            } catch { $false }
        }).Count
        $rows += @{ date=$day.ToString('yyyy-MM-dd'); remaining=$remaining }
    }

    # Convert to universal display format
    $columns = @{
        "date" = @{ Header = "Date"; Width = 12; Alignment = "Center"; Editable = $false }
        "remaining" = @{ Header = "Remaining"; Width = 12; Alignment = "Right"; Editable = $false }
    }

    # Convert rows to PSCustomObject format
    $dataObjects = @()
    foreach ($row in $rows) {
        $obj = New-Object PSCustomObject
        foreach ($key in $row.Keys) {
            $obj | Add-Member -NotePropertyName $key -NotePropertyValue $row[$key]
        }
        $dataObjects += $obj
    }

    Show-PmcCustomGrid -Domain "stats" -Columns $columns -Data $dataObjects -Title 'BURNDOWN (next 7 days)'
    Show-PmcTip 'Simple burndown: remaining tasks projected by day'

    Write-PmcDebug -Level 2 -Category "Analytics" -Message "Burndown completed"
}

function Get-PmcVelocity {
    param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category "Analytics" -Message "Starting velocity"

    $data = Get-PmcDataAlias
    $startOfWeek = (Get-Date).Date.AddDays(-1 * (([int](Get-Date).DayOfWeek + 6) % 7))
    $rows = @()
    for ($w=0; $w -lt 4; $w++) {
        $wStart = $startOfWeek.AddDays(-7*$w)
        $wEnd = $wStart.AddDays(7)
        $done = @($data.tasks | Where-Object { $_.status -eq 'completed' -and $_.completed -and ([datetime]$_.completed) -ge $wStart -and ([datetime]$_.completed) -lt $wEnd }).Count
        $mins = @($data.timelogs | Where-Object { $_.date -and ([datetime]$_.date) -ge $wStart -and ([datetime]$_.date) -lt $wEnd } | Measure-Object minutes -Sum).Sum
        $hrs = [Math]::Round(($mins/60),1)
        $rows += @{ week=$wStart.ToString('yyyy-MM-dd'); completed=$done; hours=$hrs }
    }

    # Convert to universal display format
    $columns = @{
        "week" = @{ Header = "Week"; Width = 12; Alignment = "Center"; Editable = $false }
        "completed" = @{ Header = "Done"; Width = 8; Alignment = "Right"; Editable = $false }
        "hours" = @{ Header = "Hours"; Width = 8; Alignment = "Right"; Editable = $false }
    }

    # Convert rows to PSCustomObject format and sort
    $sortedRows = $rows | Sort-Object week
    $dataObjects = @()
    foreach ($row in $sortedRows) {
        $obj = New-Object PSCustomObject
        foreach ($key in $row.Keys) {
            $obj | Add-Member -NotePropertyName $key -NotePropertyValue $row[$key]
        }
        $dataObjects += $obj
    }

    Show-PmcCustomGrid -Domain "stats" -Columns $columns -Data $dataObjects -Title 'VELOCITY (last 4 weeks)'
    Write-PmcDebug -Level 2 -Category "Analytics" -Message "Velocity completed"
}

Export-ModuleMember -Function Get-PmcStatistics, Show-PmcBurndownChart, Get-PmcVelocity



# END FILE: ./module/Pmc.Strict/src/Analytics.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/AstCommandParser.ps1
# SIZE: 11.39 KB
# MODIFIED: 2025-09-23 16:55:09
# ================================================================================

# AST-based command parser for PMC
# Replaces regex-heavy Parse-PmcArgsFromTokens with structured parsing

Set-StrictMode -Version Latest

# Token types for semantic parsing
enum PmcTokenType {
    Domain
    Action
    ProjectRef    # @project
    Priority      # p1, p2, p3
    Tag          # #tag
    DueDate      # due:date
    TaskId       # task:123
    StringLiteral # "quoted text"
    Flag         # -i, --interactive
    Separator    # --
    FreeText     # unstructured text
}

class PmcParsedToken {
    [PmcTokenType]$Type
    [string]$Value
    [string]$RawValue
    [int]$Position

    PmcParsedToken([PmcTokenType]$type, [string]$value, [string]$raw, [int]$pos) {
        $this.Type = $type
        $this.Value = $value
        $this.RawValue = $raw
        $this.Position = $pos
    }
}

class PmcCommandAst {
    [string]$Domain
    [string]$Action
    [hashtable]$Args = @{}
    [string[]]$FreeText = @()
    [PmcParsedToken[]]$Tokens = @()
    [string]$Raw

    PmcCommandAst([string]$raw) {
        $this.Raw = $raw
        $this.Args = @{}
        $this.FreeText = @()
        $this.Tokens = @()
    }
}

# Main AST parsing function
function ConvertTo-PmcCommandAst {
    param(
        [Parameter(Mandatory=$true)]
        [string]$CommandText
    )

    try {
        # Use PowerShell AST to get proper tokenization
        $ast = [System.Management.Automation.Language.Parser]::ParseInput($CommandText, [ref]$null, [ref]$null)

        # Find the command AST node
        $cmdAst = $ast.FindAll({$args[0] -is [System.Management.Automation.Language.CommandAst]}, $true) | Select-Object -First 1

        if (-not $cmdAst) {
            Write-PmcDebug -Level 2 -Category 'AstParser' -Message "No command AST found, trying fallback parsing"
            throw "No command found in input"
        }

        $result = [PmcCommandAst]::new($CommandText)
        $elements = $cmdAst.CommandElements

        if ($elements.Count -lt 1) {
            throw "Empty command"
        }

        # Check if PowerShell AST stripped important tokens (like #tags)
        $originalTokenCount = ($CommandText -split '\s+').Count
        $astTokenCount = $elements.Count

        if ($astTokenCount -lt $originalTokenCount) {
            Write-PmcDebug -Level 2 -Category 'AstParser' -Message "PowerShell AST stripped tokens (comments?), falling back to manual parsing"
            throw "AST incomplete, using fallback"
        }

        # Parse domain (first element)
        $result.Domain = $elements[0].Extent.Text.ToLower()

        # Parse action (second element, if exists)
        if ($elements.Count -gt 1) {
            $result.Action = $elements[1].Extent.Text.ToLower()
        }

        # Parse remaining arguments (semantic parsing)
        if ($elements.Count -gt 2) {
            $argElements = $elements[2..($elements.Count-1)]
            Parse-CommandArguments -Elements $argElements -Result $result
        }

        return $result

    } catch {
        Write-PmcDebug -Level 1 -Category 'AstParser' -Message "AST parsing failed: $_" -Data @{ CommandText = $CommandText }

        # No fallback - throw the error so we know AST isn't working
        throw "AST parsing failed: $_"
    }
}

# Semantic argument parsing
function Parse-CommandArguments {
    param(
        [System.Management.Automation.Language.CommandElementAst[]]$Elements,
        [PmcCommandAst]$Result
    )

    $position = 0
    $seenSeparator = $false

    foreach ($element in $Elements) {
        $text = $element.Extent.Text
        $position++

        # Handle separator (everything after -- is free text)
        if ($text -eq '--') {
            $seenSeparator = $true
            $token = [PmcParsedToken]::new([PmcTokenType]::Separator, '', $text, $position)
            $Result.Tokens += $token
            continue
        }

        if ($seenSeparator) {
            # Everything after -- goes to free text
            $token = [PmcParsedToken]::new([PmcTokenType]::FreeText, $text, $text, $position)
            $Result.Tokens += $token
            $Result.FreeText += $text
            continue
        }

        # Semantic parsing based on token patterns
        $tokenInfo = Parse-SemanticToken -Text $text -Position $position
        $Result.Tokens += $tokenInfo

        # Add to appropriate result field based on token type
        switch ($tokenInfo.Type) {
            ([PmcTokenType]::ProjectRef) {
                $Result.Args['project'] = $tokenInfo.Value
            }
            ([PmcTokenType]::Priority) {
                $Result.Args['priority'] = $tokenInfo.Value
            }
            ([PmcTokenType]::Tag) {
                if (-not $Result.Args.ContainsKey('tags')) { $Result.Args['tags'] = @() }
                $Result.Args['tags'] += $tokenInfo.Value
            }
            ([PmcTokenType]::DueDate) {
                $Result.Args['due'] = $tokenInfo.Value
            }
            ([PmcTokenType]::TaskId) {
                $Result.Args['taskId'] = [int]$tokenInfo.Value
            }
            ([PmcTokenType]::Flag) {
                # Handle flags like -i, --interactive
                $flagName = $tokenInfo.Value
                $Result.Args[$flagName] = $true
            }
            ([PmcTokenType]::StringLiteral) {
                # Quoted strings go to free text (usually task titles, descriptions)
                $Result.FreeText += $tokenInfo.Value
            }
            ([PmcTokenType]::FreeText) {
                $Result.FreeText += $tokenInfo.Value
            }
        }
    }
}

# Parse individual tokens semantically
function Parse-SemanticToken {
    param(
        [string]$Text,
        [int]$Position
    )

    # Project reference: @project
    if ($Text -match '^@(.+)$') {
        return [PmcParsedToken]::new([PmcTokenType]::ProjectRef, $matches[1], $Text, $Position)
    }

    # Priority: p1, p2, p3
    if ($Text -match '^p([1-3])$') {
        return [PmcParsedToken]::new([PmcTokenType]::Priority, $Text, $Text, $Position)
    }

    # Tag: #tag
    if ($Text -match '^#(.+)$') {
        return [PmcParsedToken]::new([PmcTokenType]::Tag, $matches[1], $Text, $Position)
    }

    # Due date: due:date
    if ($Text -match '^due:(.+)$') {
        return [PmcParsedToken]::new([PmcTokenType]::DueDate, $matches[1], $Text, $Position)
    }

    # Task ID: task:123
    if ($Text -match '^task:(\d+)$') {
        return [PmcParsedToken]::new([PmcTokenType]::TaskId, $matches[1], $Text, $Position)
    }

    # Flags: -i, --interactive
    if ($Text -match '^-+(.+)$') {
        $flagName = $matches[1]
        # Normalize common flags
        switch ($flagName.ToLower()) {
            'i' { $flagName = 'interactive' }
            'interactive' { $flagName = 'interactive' }
        }
        return [PmcParsedToken]::new([PmcTokenType]::Flag, $flagName, $Text, $Position)
    }

    # Quoted strings (AST should handle these, but fallback)
    if ($Text -match '^"(.*)"$') {
        return [PmcParsedToken]::new([PmcTokenType]::StringLiteral, $matches[1], $Text, $Position)
    }

    # Everything else is free text
    return [PmcParsedToken]::new([PmcTokenType]::FreeText, $Text, $Text, $Position)
}

# Fallback parser when AST fails
function ConvertTo-PmcCommandAstFallback {
    param([string]$CommandText)

    $result = [PmcCommandAst]::new($CommandText)
    $tokens = ConvertTo-PmcTokens $CommandText

    if ($tokens.Count -gt 0) { $result.Domain = $tokens[0].ToLower() }
    if ($tokens.Count -gt 1) { $result.Action = $tokens[1].ToLower() }

    # Parse remaining tokens
    if ($tokens.Count -gt 2) {
        $argTokens = $tokens[2..($tokens.Count-1)]
        $position = 2

        foreach ($token in $argTokens) {
            $position++
            $tokenInfo = Parse-SemanticToken -Text $token -Position $position
            $result.Tokens += $tokenInfo

            # Add to result like above
            switch ($tokenInfo.Type) {
                ([PmcTokenType]::ProjectRef) { $result.Args['project'] = $tokenInfo.Value }
                ([PmcTokenType]::Priority) { $result.Args['priority'] = $tokenInfo.Value }
                ([PmcTokenType]::Tag) {
                    if (-not $result.Args.ContainsKey('tags')) { $result.Args['tags'] = @() }
                    $result.Args['tags'] += $tokenInfo.Value
                }
                ([PmcTokenType]::DueDate) { $result.Args['due'] = $tokenInfo.Value }
                ([PmcTokenType]::TaskId) { $result.Args['taskId'] = [int]$tokenInfo.Value }
                ([PmcTokenType]::Flag) { $result.Args[$tokenInfo.Value] = $true }
                default { $result.FreeText += $tokenInfo.Value }
            }
        }
    }

    return $result
}

# Replace the existing Parse-PmcArgsFromTokens function
function Parse-PmcArgsFromTokensAst {
    param(
        [string[]]$Tokens,
        [int]$StartIndex = 0
    )

    # Reconstruct command from tokens
    $commandText = ($Tokens[$StartIndex..($Tokens.Count-1)] -join ' ')
    $astResult = ConvertTo-PmcCommandAst -CommandText $commandText

    return @{
        Args = $astResult.Args
        Free = $astResult.FreeText
    }
}

# Get completion context from AST
function Get-PmcCompletionContextFromAst {
    param(
        [string]$Buffer,
        [int]$CursorPos
    )

    try {
        # Parse what we have so far - handle empty/partial commands
        if ([string]::IsNullOrWhiteSpace($Buffer)) {
            $ast = [PmcCommandAst]::new("")
        } else {
            $ast = ConvertTo-PmcCommandAst -CommandText $Buffer
        }

        # Determine what kind of completion we need
        $context = @{
            Domain = $ast.Domain
            Action = $ast.Action
            Args = $ast.Args
            LastToken = $null
            ExpectedType = $null
            Position = $ast.Tokens.Count
        }

        # Find the token at cursor position
        $beforeCursor = $Buffer.Substring(0, [Math]::Min($CursorPos, $Buffer.Length))
        $lastSpace = $beforeCursor.LastIndexOf(' ')

        if ($lastSpace -ge 0 -and $lastSpace -lt $beforeCursor.Length - 1) {
            $context.LastToken = $beforeCursor.Substring($lastSpace + 1)
        } elseif ($lastSpace -eq $beforeCursor.Length - 1) {
            $context.LastToken = ''
        } else {
            $context.LastToken = $beforeCursor
        }

        # Determine expected completion type
        $context.ExpectedType = Get-ExpectedCompletionType -Context $context

        return $context

    } catch {
        Write-PmcDebug -Level 2 -Category 'AstCompletion' -Message "AST completion context failed: $_"
        return $null
    }
}

# Determine what type of completion to show
function Get-ExpectedCompletionType {
    param([hashtable]$Context)

    $lastToken = if ($Context.LastToken) { $Context.LastToken } else { '' }

    # If last token has a prefix, complete that type
    if ($lastToken -and $lastToken.StartsWith('@')) { return 'Project' }
    if ($lastToken -and $lastToken.StartsWith('#')) { return 'Tag' }
    if ($lastToken -and $lastToken.StartsWith('p')) { return 'Priority' }
    if ($lastToken -and $lastToken.StartsWith('due:')) { return 'Date' }
    if ($lastToken -and $lastToken.StartsWith('task:')) { return 'TaskId' }

    # If we don't have domain/action yet
    if (-not $Context.Domain -or [string]::IsNullOrEmpty($Context.Domain)) { return 'Domain' }
    if (-not $Context.Action -or [string]::IsNullOrEmpty($Context.Action)) { return 'Action' }

    # Otherwise, suggest argument types
    return 'Arguments'
}

Export-ModuleMember -Function ConvertTo-PmcCommandAst, Parse-PmcArgsFromTokensAst, Get-PmcCompletionContextFromAst

# END FILE: ./module/Pmc.Strict/src/AstCommandParser.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/AstCompletion.ps1
# SIZE: 9.76 KB
# MODIFIED: 2025-09-23 16:55:16
# ================================================================================

# AST-based tab completion for PMC commands
# Replaces regex-based completion with semantic understanding

Set-StrictMode -Version Latest

# Enhanced completion providers using AST context
function Get-PmcCompletionsFromAst {
    param(
        [string]$Buffer,
        [int]$CursorPos
    )

    try {
        # Handle empty buffer case
        if ([string]::IsNullOrWhiteSpace($Buffer)) {
            Write-PmcDebug -Level 2 -Category 'AstCompletion' -Message "Empty buffer, providing domain completions"
            return Get-DomainCompletions
        }

        $context = Get-PmcCompletionContextFromAst -Buffer $Buffer -CursorPos $CursorPos

        if (-not $context) {
            Write-PmcDebug -Level 2 -Category 'AstCompletion' -Message "No AST context available, falling back"
            return @()
        }

        Write-PmcDebug -Level 2 -Category 'AstCompletion' -Message "AST completion context" -Data @{
            Domain = $context.Domain
            Action = $context.Action
            ExpectedType = $context.ExpectedType
            LastToken = $context.LastToken
        }

        # Get completions based on expected type
        $completions = @()
        switch ($context.ExpectedType) {
            'Domain' {
                $completions = Get-DomainCompletions -Filter $context.LastToken
            }
            'Action' {
                $completions = Get-ActionCompletions -Domain $context.Domain -Filter $context.LastToken
            }
            'Project' {
                $completions = Get-ProjectCompletions -Filter $context.LastToken
            }
            'Priority' {
                $completions = Get-PriorityCompletions -Filter $context.LastToken
            }
            'Tag' {
                $completions = Get-TagCompletions -Filter $context.LastToken
            }
            'Date' {
                $completions = Get-DateCompletions -Filter $context.LastToken
            }
            'TaskId' {
                $completions = Get-TaskIdCompletions -Filter $context.LastToken
            }
            'Arguments' {
                $completions = Get-ArgumentCompletions -Context $context
            }
            default {
                $completions = Get-GenericCompletions -Context $context
            }
        }

        Write-PmcDebug -Level 2 -Category 'AstCompletion' -Message "Completions generated" -Data @{
            Count = $completions.Count
            Type = $context.ExpectedType
        }

        return $completions

    } catch {
        Write-PmcDebug -Level 1 -Category 'AstCompletion' -Message "AST completion failed: $_" -Data @{
            Buffer = $Buffer
            CursorPos = $CursorPos
            Exception = $_.Exception.Message
        }
        # No fallback - re-throw the error so we know AST completion isn't working
        throw "AST completion failed: $_"
    }
}

# Domain completions
function Get-DomainCompletions {
    param([string]$Filter = "")

    $domains = @('task', 'project', 'time', 'timer', 'activity', 'help', 'q')

    if ([string]::IsNullOrEmpty($Filter)) {
        return $domains
    }

    return $domains | Where-Object { $_.StartsWith($Filter, [StringComparison]::OrdinalIgnoreCase) }
}

# Action completions based on domain
function Get-ActionCompletions {
    param(
        [string]$Domain,
        [string]$Filter = ""
    )

    $actions = @()

    if ([string]::IsNullOrEmpty($Domain)) {
        Write-PmcDebug -Level 2 -Category 'AstCompletion' -Message "No domain provided for action completion"
        return @()
    }

    switch ($Domain.ToLower()) {
        'task' {
            $actions = @('add', 'list', 'view', 'update', 'done', 'delete', 'move', 'postpone', 'duplicate', 'note', 'edit', 'search', 'priority', 'agenda', 'week', 'month')
        }
        'project' {
            $actions = @('add', 'list', 'view', 'update', 'edit', 'rename', 'delete', 'archive', 'set-fields', 'show-fields', 'stats', 'info', 'recent')
        }
        'time' {
            $actions = @('log', 'report', 'list', 'edit', 'delete')
        }
        'timer' {
            $actions = @('start', 'stop', 'status')
        }
        'activity' {
            $actions = @('list')
        }
        'help' {
            $actions = @('show', 'guide', 'examples', 'query', 'domain', 'command', 'search')
        }
        default {
            return @()
        }
    }

    if ([string]::IsNullOrEmpty($Filter)) {
        return $actions
    }

    return $actions | Where-Object { $_.StartsWith($Filter, [StringComparison]::OrdinalIgnoreCase) }
}

# Project completions
function Get-ProjectCompletions {
    param([string]$Filter = "")

    try {
        $data = Get-PmcData
        $projects = @()

        foreach ($project in $data.projects) {
            $name = "@" + $project.name
            $projects += $name
        }

        if ([string]::IsNullOrEmpty($Filter)) {
            return $projects
        }

        # Handle @ prefix in filter
        $searchFilter = if ($Filter.StartsWith('@')) { $Filter } else { "@" + $Filter }

        return $projects | Where-Object { $_.StartsWith($searchFilter, [StringComparison]::OrdinalIgnoreCase) }

    } catch {
        Write-PmcDebug -Level 2 -Category 'AstCompletion' -Message "Project completion error: $_"
        return @('@work', '@personal', '@urgent')  # Fallback
    }
}

# Priority completions
function Get-PriorityCompletions {
    param([string]$Filter = "")

    $priorities = @('p1', 'p2', 'p3')

    if ([string]::IsNullOrEmpty($Filter)) {
        return $priorities
    }

    return $priorities | Where-Object { $_.StartsWith($Filter, [StringComparison]::OrdinalIgnoreCase) }
}

# Tag completions
function Get-TagCompletions {
    param([string]$Filter = "")

    try {
        $data = Get-PmcData
        $tags = @()

        foreach ($task in $data.tasks) {
            if ($task.tags) {
                foreach ($tag in $task.tags) {
                    $tagName = "#" + $tag
                    if ($tags -notcontains $tagName) {
                        $tags += $tagName
                    }
                }
            }
        }

        if ([string]::IsNullOrEmpty($Filter)) {
            return $tags
        }

        # Handle # prefix in filter
        $searchFilter = if ($Filter.StartsWith('#')) { $Filter } else { "#" + $Filter }

        return $tags | Where-Object { $_.StartsWith($searchFilter, [StringComparison]::OrdinalIgnoreCase) }

    } catch {
        Write-PmcDebug -Level 2 -Category 'AstCompletion' -Message "Tag completion error: $_"
        return @('#urgent', '#bug', '#review')  # Fallback
    }
}

# Date completions
function Get-DateCompletions {
    param([string]$Filter = "")

    $dates = @(
        'due:today',
        'due:tomorrow',
        'due:friday',
        'due:+1d',
        'due:+1w',
        'due:+1m',
        'due:2024-12-25'
    )

    if ([string]::IsNullOrEmpty($Filter)) {
        return $dates
    }

    return $dates | Where-Object { $_.StartsWith($Filter, [StringComparison]::OrdinalIgnoreCase) }
}

# Task ID completions
function Get-TaskIdCompletions {
    param([string]$Filter = "")

    try {
        $data = Get-PmcData
        $taskIds = @()

        foreach ($task in $data.tasks) {
            if ($task.id) {
                $taskId = "task:" + $task.id
                $taskIds += $taskId
            }
        }

        if ([string]::IsNullOrEmpty($Filter)) {
            return $taskIds | Select-Object -First 10  # Limit to recent tasks
        }

        return $taskIds | Where-Object { $_.StartsWith($Filter, [StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 10

    } catch {
        Write-PmcDebug -Level 2 -Category 'AstCompletion' -Message "Task ID completion error: $_"
        return @()
    }
}

# Argument completions when we already have domain/action
function Get-ArgumentCompletions {
    param([hashtable]$Context)

    $completions = @()

    # Add common argument types that haven't been used yet
    if (-not $Context.Args.ContainsKey('project')) {
        $completions += '@'
    }

    if (-not $Context.Args.ContainsKey('priority')) {
        $completions += @('p1', 'p2', 'p3')
    }

    if (-not $Context.Args.ContainsKey('tags')) {
        $completions += '#'
    }

    if (-not $Context.Args.ContainsKey('due') -and $Context.Domain -eq 'task') {
        $completions += 'due:'
    }

    if (-not $Context.Args.ContainsKey('taskId') -and $Context.Action -in @('view', 'update', 'done', 'delete')) {
        $completions += 'task:'
    }

    return $completions
}

# Generic completions fallback
function Get-GenericCompletions {
    param([hashtable]$Context)

    $completions = @()

    # Suggest based on domain and action
    switch ("$($Context.Domain):$($Context.Action)") {
        'task:add' {
            $completions += @('@', 'p1', 'p2', 'p3', '#', 'due:')
        }
        'task:list' {
            $completions += @('@', 'p1', 'p2', 'p3', '#', 'due:', 'overdue')
        }
        'task:view' {
            $completions += @('task:')
        }
        'project:list' {
            $completions += @('@')
        }
        'time:log' {
            $completions += @('@', 'task:', '#')
        }
        default {
            $completions += @('@', 'p1', '#')
        }
    }

    return $completions
}

# Replace completion logic in Interactive.ps1
function Get-CompletionsForStateAst {
    param([hashtable]$Context)

    # Try AST-based completion first
    $buffer = $Context.Buffer ?? ""
    $cursorPos = $Context.CursorPos ?? 0

    $astCompletions = Get-PmcCompletionsFromAst -Buffer $buffer -CursorPos $cursorPos

    if ($astCompletions.Count -gt 0) {
        return $astCompletions
    }

    # Fallback to existing system if AST fails
    Write-PmcDebug -Level 2 -Category 'AstCompletion' -Message "AST completion failed, using fallback"
    return @()
}

Export-ModuleMember -Function Get-PmcCompletionsFromAst, Get-CompletionsForStateAst

# END FILE: ./module/Pmc.Strict/src/AstCompletion.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/CommandMap.ps1
# SIZE: 11.27 KB
# MODIFIED: 2025-09-23 21:08:34
# ================================================================================

# Canonical domain -> action -> function map (strict)

$Script:PmcCommandMap = @{
    task = @{
        add     = 'Add-PmcTask'
        list    = 'Get-PmcTaskList'
        view    = 'Show-PmcTask'
        update  = 'Set-PmcTask'
        done    = 'Complete-PmcTask'
        delete  = 'Remove-PmcTask'
        move    = 'Move-PmcTask'
        postpone= 'Set-PmcTaskPostponed'
        duplicate='Copy-PmcTask'
        note    = 'Add-PmcTaskNote'
        edit    = 'Edit-PmcTask'
        search  = 'Find-PmcTask'
        priority= 'Set-PmcTaskPriority'
        agenda  = 'Show-PmcAgenda'
        week    = 'Show-PmcWeekTasksInteractive'
        month   = 'Show-PmcMonthTasksInteractive'
    }
    project = @{
        add     = 'Add-PmcProject'
        list    = 'Get-PmcProjectList'
        view    = 'Show-PmcProject'
        update  = 'Set-PmcProject'
        edit    = 'Edit-PmcProject'
        rename  = 'Rename-PmcProject'
        delete  = 'Remove-PmcProject'
        archive = 'Set-PmcProjectArchived'
        'set-fields' = 'Set-PmcProjectFields'
        'show-fields'= 'Show-PmcProjectFields'
        stats   = 'Get-PmcProjectStats'
        info    = 'Show-PmcProjectInfo'
        recent  = 'Get-PmcRecentProjects'
    }
    activity = @{
        list    = 'Get-PmcActivityList'
    }
    time = @{
        log     = 'Add-PmcTimeEntry'
        report  = 'Get-PmcTimeReport'
        list    = 'Get-PmcTimeList'
        edit    = 'Edit-PmcTimeEntry'
        delete  = 'Remove-PmcTimeEntry'
    }
    timer = @{
        start   = 'Start-PmcTimer'
        stop    = 'Stop-PmcTimer'
        status  = 'Get-PmcTimerStatus'
    }
    template = @{
        save    = 'Save-PmcTemplate'
        apply   = 'Invoke-PmcTemplate'
        list    = 'Get-PmcTemplateList'
        remove  = 'Remove-PmcTemplate'
    }
    recurring = @{
        add     = 'Add-PmcRecurringTask'
    }
    alias = @{
        add     = 'Add-PmcAlias'
        remove  = 'Remove-PmcAlias'
    }
    dep = @{
        add     = 'Add-PmcDependency'
        remove  = 'Remove-PmcDependency'
        show    = 'Show-PmcDependencies'
        graph   = 'Show-PmcDependencyGraph'
    }
    focus = @{
        set     = 'Set-PmcFocus'
        clear   = 'Clear-PmcFocus'
        status  = 'Get-PmcFocusStatus'
    }
    system = @{
        undo    = 'Invoke-PmcUndo'
        redo    = 'Invoke-PmcRedo'
        backup  = 'New-PmcBackup'
        clean   = 'Clear-PmcCompletedTasks'
    }
    view = @{
        today     = 'Show-PmcTodayTasksInteractive'
        tomorrow  = 'Show-PmcTomorrowTasksInteractive'
        overdue   = 'Show-PmcOverdueTasksInteractive'
        upcoming  = 'Show-PmcUpcomingTasksInteractive'
        blocked   = 'Show-PmcBlockedTasksInteractive'
        noduedate = 'Show-PmcTasksWithoutDueDateInteractive'
        projects  = 'Show-PmcProjectsInteractive'
        next      = 'Show-PmcNextTasksInteractive'
    }
    excel = @{
        import   = 'Import-PmcExcelData'
        view     = 'Show-PmcExcelPreview'
        latest   = 'Get-PmcLatestExcelFile'
    }
    xflow = @{
        'browse-source' = 'Set-PmcXFlowSourcePathInteractive'
        'browse-dest'   = 'Set-PmcXFlowDestPathInteractive'
        'preview'       = 'Show-PmcXFlowPreview'
        'run'           = 'Invoke-PmcXFlowRun'
        'export'        = 'Export-PmcXFlowText'
        'import-mappings' = 'Import-PmcXFlowMappingsFromFile'
        'set-latest'    = 'Set-PmcXFlowLatestFromFile'
        'config'        = 'Show-PmcXFlowConfig'
    }
    theme = @{
        reset    = 'Reset-PmcTheme'
        adjust   = 'Edit-PmcTheme'
        list     = 'Get-PmcThemeList'
        apply    = 'Apply-PmcTheme'
        info     = 'Show-PmcThemeInfo'
    }
    interactive = @{
        status   = 'Get-PmcInteractiveStatus'
    }
    config = @{
        show    = 'Show-PmcConfig'
        edit    = 'Edit-PmcConfig'
        set     = 'Set-PmcConfigValue'
        reload  = 'Reload-PmcConfig'
        validate= 'Validate-PmcConfig'
        icons   = 'Set-PmcIconMode'
    }
    import = @{
        tasks   = 'Import-PmcTasks'
    }
    export = @{
        tasks   = 'Export-PmcTasks'
    }
    show = @{
        aliases = 'Get-PmcAliasList'
        commands= 'Show-PmcCommands'
    }
    help = @{
        show     = 'Show-PmcSmartHelp'     # Interactive help browser (full takeover)
        domain   = 'Show-PmcHelpDomain'    # Static print of domain actions
        command  = 'Show-PmcHelpCommand'   # Static print of specific command (args/usage)
        query    = 'Show-PmcHelpQuery'     # Static print of query language overview
        guide    = 'Show-PmcHelpGuide'     # Interactive guides for query/kanban
        examples = 'Show-PmcHelpExamples'  # Practical examples
        search   = 'Show-PmcHelpSearch'    # Search across help content and commands
    }
}

# Single-word shortcuts (domain-less commands)
$Script:PmcShortcutMap = @{
    add       = 'Add-PmcTask'
    done      = 'Complete-PmcTask'
    delete    = 'Remove-PmcTask'
    update    = 'Set-PmcTask'
    move      = 'Move-PmcTask'
    postpone  = 'Set-PmcTaskPostponed'
    duplicate = 'Copy-PmcTask'
    note      = 'Add-PmcTaskNote'
    edit      = 'Edit-PmcTask'
    list      = 'Get-PmcTaskList'
    search    = 'Find-PmcTask'
    priority  = 'Set-PmcTaskPriority'
    agenda    = 'Show-PmcAgenda'
    week      = 'Show-PmcWeekTasksInteractive'
    month     = 'Show-PmcMonthTasksInteractive'
    log       = 'Add-PmcTimeEntry'
    report    = 'Get-PmcTimeReport'
    today     = 'Show-PmcTodayTasksInteractive'
    tomorrow  = 'Show-PmcTomorrowTasksInteractive'
    overdue   = 'Show-PmcOverdueTasksInteractive'
    upcoming  = 'Show-PmcUpcomingTasksInteractive'
    blocked   = 'Show-PmcBlockedTasksInteractive'
    noduedate = 'Show-PmcTasksWithoutDueDateInteractive'
    projects  = 'Show-PmcProjectsInteractive'
    # Explicit interactive aliases
    itoday    = 'Show-PmcTodayTasks'
    ioverdue  = 'Show-PmcOverdueTasks'
    iagenda   = 'Show-PmcAgenda'
    iprojects = 'Show-PmcProjectList'
    itasks    = 'Show-PmcTodayTasks'
    undo      = 'Invoke-PmcUndo'
    redo      = 'Invoke-PmcRedo'
    backup    = 'New-PmcBackup'
    clean     = 'Clear-PmcCompletedTasks'
    focus     = 'Set-PmcFocus'
    unfocus   = 'Clear-PmcFocus'
    context   = 'Get-PmcFocusStatus'
    next      = 'Show-PmcNextTasksInteractive'
    stats     = 'Get-PmcStats'
    burndown  = 'Show-PmcBurndown'
    velocity  = 'Get-PmcVelocity'
    theme     = 'Set-PmcTheme'
    prefs     = 'Show-PmcPreferences'
    '#'       = 'Invoke-PmcShortcutNumber'
    alias     = 'Get-PmcAliasList'
    time      = 'Get-PmcTimeList'
    config    = 'Validate-PmcConfig'
    review    = 'Start-PmcReview'
    import    = 'Import-PmcTasks'
    export    = 'Export-PmcTasks'
    tasks     = 'Show-PmcAllTasksInteractive'
    q         = 'Invoke-PmcQuery'
}

# Minimal descriptions for help
$Script:PmcCommandMeta = @{
    'task add'      = @{ Desc='Add a new task' }
    'task list'     = @{ Desc='List tasks' }
    'task done'     = @{ Desc='Complete a task' }
    'project add'   = @{ Desc='Create project' }
    'project list'  = @{ Desc='List projects' }
    'time log'      = @{ Desc='Log time entry' }
    'time report'   = @{ Desc='Show time report' }
    'time list'     = @{ Desc='List time logs' }
    'timer start'   = @{ Desc='Start timer' }
    'timer stop'    = @{ Desc='Stop timer' }
    'timer status'  = @{ Desc='Show timer' }
    'dep add'       = @{ Desc='Add task dependency' }
    'dep remove'    = @{ Desc='Remove task dependency' }
    'dep show'      = @{ Desc='Show task dependencies' }
    'dep graph'     = @{ Desc='Visual dependency graph' }
    'focus set'     = @{ Desc='Set project context' }
    'focus clear'   = @{ Desc='Clear project context' }
    'focus status'  = @{ Desc='Show current context' }
    'system undo'   = @{ Desc='Undo last action' }
    'system redo'   = @{ Desc='Redo last action' }
    'system backup' = @{ Desc='Create data backup' }
    'system clean'  = @{ Desc='Clean completed tasks' }
    'view today'    = @{ Desc='Tasks due today' }
    'view tomorrow' = @{ Desc='Tasks due tomorrow' }
    'view overdue'  = @{ Desc='Overdue tasks' }
    'view upcoming' = @{ Desc='Upcoming tasks (7 days)' }
    'view blocked'  = @{ Desc='Tasks blocked by dependencies' }
    'view noduedate'= @{ Desc='Tasks without due dates' }
    'view projects' = @{ Desc='Projects dashboard' }
    'view next'     = @{ Desc='Next actions summary' }
    'excel import'  = @{ Desc='Import tasks from Excel/CSV' }
    'excel view'    = @{ Desc='Preview Excel/CSV import' }
    'excel latest'  = @{ Desc='Show latest Excel/CSV file' }
    'xflow browse-source' = @{ Desc='Choose source Excel file (interactive)' }
    'xflow browse-dest'   = @{ Desc='Choose destination Excel file (interactive)' }
    'xflow preview' = @{ Desc='Preview first mapped fields from source' }
    'xflow run'     = @{ Desc='Run Excel mapping; optional text export' }
    'xflow export'  = @{ Desc='Export last extract to CSV/JSON' }
    'xflow import-mappings' = @{ Desc='Import field mappings from settings.json' }
    'xflow set-latest' = @{ Desc='Set latest extract from JSON file' }
    'xflow config' = @{ Desc='Show current xflow configuration' }
    'theme reset'   = @{ Desc='Reset theme to default' }
    'theme adjust'  = @{ Desc='Adjust theme interactively' }
    'config icons'  = @{ Desc='Set icons: ascii|emoji' }
    'stats'         = @{ Desc='Productivity statistics' }
    'burndown'      = @{ Desc='Burndown overview (7d)' }
    'velocity'      = @{ Desc='Velocity (last 4 weeks)' }
    'prefs'         = @{ Desc='Edit preferences' }
    'alias add'     = @{ Desc='Add user alias' }
    'alias remove'  = @{ Desc='Remove user alias' }
    'show aliases'  = @{ Desc='Show user aliases' }
    'show commands' = @{ Desc='List all commands' }
    'help guide'    = @{ Desc='Guides for query language and kanban' }
    'help examples' = @{ Desc='Examples for queries and kanban flows' }
    'help query'    = @{ Desc='Query language overview' }
    'help search'   = @{ Desc='Search help content and commands' }
    'project stats' = @{ Desc='Project statistics' }
    'project info'  = @{ Desc='Project information' }
    'project recent'= @{ Desc='Recent projects' }
    'import tasks'  = @{ Desc='Import tasks from CSV/JSON' }
    'export tasks'  = @{ Desc='Export tasks to CSV/JSON' }
    'review'        = @{ Desc='Weekly review workflow' }
}

# Ensure Universal Display is available and shortcuts are registered.
function Ensure-PmcUniversalDisplay {
    try {
        $ud = Join-Path $PSScriptRoot 'UniversalDisplay.ps1'
        # Load if core entry not available
        if (-not (Get-Command Show-PmcData -ErrorAction SilentlyContinue)) {
            if (-not (Test-Path $ud)) { throw "UniversalDisplay.ps1 not found at $ud" }
            . $ud
        }
        if (Get-Command Register-PmcUniversalCommands -ErrorAction SilentlyContinue) {
            Register-PmcUniversalCommands
            return $true
        }
        throw 'Register-PmcUniversalCommands not found after loading UniversalDisplay.ps1'
    } catch {
        # Write-PmcDebug -Level 1 -Category 'UniversalDisplay' -Message "Initialization failed" -Data @{ Error = $_.ToString() }
        Write-Warning "UniversalDisplay initialization failed: $($_.ToString())"
        return $false
    }
}

# Initialize Universal Display system when this module is loaded
# Ensure-PmcUniversalDisplay  # Commented out to prevent CommandMap loading issues


# END FILE: ./module/Pmc.Strict/src/CommandMap.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/ComputedFields.ps1
# SIZE: 7.54 KB
# MODIFIED: 2025-09-22 15:23:10
# ================================================================================

Set-StrictMode -Version Latest

# Computed metrics and relations registry for PMC Query Engine

function Get-PmcComputedRegistry {
    # Returns a hashtable keyed by domain with metrics definitions
    # Each metric: @{ Name; AppliesTo; DependsOn=@('timelog'); Type; Resolver=[scriptblock] }
    $weekRange = {
        $today = (Get-Date).Date
        $dow = [int]$today.DayOfWeek # Sunday=0
        $start = $today.AddDays(-$dow) # week starts Sunday
        $end = $start.AddDays(7)
        @{ Start=$start; End=$end }
    }

    $taskMetrics = @{
        time_week = @{
            Name='time_week'; AppliesTo='task'; DependsOn=@('timelog'); Type='int'
            Resolver = {
                param($row,$data)
                if (-not ($row.PSObject.Properties['id'])) { return 0 }
                $id = [int]$row.id
                $range = & $weekRange
                $logs = @($data.timelogs | Where-Object { $_ -ne $null -and $_.taskId -eq $id -and $_.date -and (try { $d=[datetime]$_.date; $d -ge $range.Start -and $d -lt $range.End } catch { $false }) })
                $mins = (@($logs | Measure-Object minutes -Sum).Sum)
                if ($mins -eq $null) { $mins = 0 }
                return [int]$mins
            }
        }
        overdue_days = @{
            Name='overdue_days'; AppliesTo='task'; DependsOn=@(); Type='int'
            Resolver = {
                param($row,$data)
                if (-not ($row.PSObject.Properties['due'])) { return 0 }
                try {
                    $d = [datetime]$row.due
                    $delta = ((Get-Date).Date - $d.Date).Days
                    return [Math]::Max(0, [int]$delta)
                } catch { return 0 }
            }
        }
        time_today = @{
            Name='time_today'; AppliesTo='task'; DependsOn=@('timelog'); Type='int'
            Resolver = {
                param($row,$data)
                if (-not ($row.PSObject.Properties['id'])) { return 0 }
                $id = [int]$row.id
                $today = (Get-Date).Date
                $logs = @($data.timelogs | Where-Object { $_ -ne $null -and $_.taskId -eq $id -and $_.date -and (try { ([datetime]$_.date).Date -eq $today } catch { $false }) })
                $mins = (@($logs | Measure-Object minutes -Sum).Sum)
                if ($mins -eq $null) { $mins = 0 }
                return [int]$mins
            }
        }
        time_month = @{
            Name='time_month'; AppliesTo='task'; DependsOn=@('timelog'); Type='int'
            Resolver = {
                param($row,$data)
                if (-not ($row.PSObject.Properties['id'])) { return 0 }
                $id = [int]$row.id
                $today = (Get-Date).Date
                $start = Get-Date -Year $today.Year -Month $today.Month -Day 1
                $end = $start.AddMonths(1)
                $logs = @($data.timelogs | Where-Object { $_ -ne $null -and $_.taskId -eq $id -and $_.date -and (try { $d=[datetime]$_.date; $d -ge $start -and $d -lt $end } catch { $false }) })
                $mins = (@($logs | Measure-Object minutes -Sum).Sum)
                if ($mins -eq $null) { $mins = 0 }
                return [int]$mins
            }
        }
    }

    $projectMetrics = @{
        task_count = @{
            Name='task_count'; AppliesTo='project'; DependsOn=@('task'); Type='int'
            Resolver = {
                param($row,$data)
                $name = if ($row.PSObject.Properties['name']) { [string]$row.name } else { '' }
                if (-not $name) { return 0 }
                $tasks = @($data.tasks | Where-Object { $_ -ne $null -and $_.PSObject.Properties['project'] -and $_.project -eq $name })
                return @($tasks).Count
            }
        }
        time_week = @{
            Name='time_week'; AppliesTo='project'; DependsOn=@('timelog'); Type='int'
            Resolver = {
                param($row,$data)
                $name = if ($row.PSObject.Properties['name']) { [string]$row.name } else { '' }
                if (-not $name) { return 0 }
                $range = & $weekRange
                $logs = @($data.timelogs | Where-Object { $_ -ne $null -and $_.project -eq $name -and $_.date -and (try { $d=[datetime]$_.date; $d -ge $range.Start -and $d -lt $range.End } catch { $false }) })
                $mins = (@($logs | Measure-Object minutes -Sum).Sum)
                if ($mins -eq $null) { $mins = 0 }
                return [int]$mins
            }
        }
        time_month = @{
            Name='time_month'; AppliesTo='project'; DependsOn=@('timelog'); Type='int'
            Resolver = {
                param($row,$data)
                $name = if ($row.PSObject.Properties['name']) { [string]$row.name } else { '' }
                if (-not $name) { return 0 }
                $today = (Get-Date).Date
                $start = Get-Date -Year $today.Year -Month $today.Month -Day 1
                $end = $start.AddMonths(1)
                $logs = @($data.timelogs | Where-Object { $_ -ne $null -and $_.project -eq $name -and $_.date -and (try { $d=[datetime]$_.date; $d -ge $start -and $d -lt $end } catch { $false }) })
                $mins = (@($logs | Measure-Object minutes -Sum).Sum)
                if ($mins -eq $null) { $mins = 0 }
                return [int]$mins
            }
        }
        overdue_task_count = @{
            Name='overdue_task_count'; AppliesTo='project'; DependsOn=@('task'); Type='int'
            Resolver = {
                param($row,$data)
                $name = if ($row.PSObject.Properties['name']) { [string]$row.name } else { '' }
                if (-not $name) { return 0 }
                $today = (Get-Date).Date
                $tasks = @($data.tasks | Where-Object { $_ -ne $null -and $_.PSObject.Properties['project'] -and $_.project -eq $name -and $_.PSObject.Properties['due'] -and (try { ([datetime]$_.due).Date -lt $today } catch { $false }) })
                return @($tasks).Count
            }
        }
    }

    return @{
        task = $taskMetrics
        project = $projectMetrics
        timelog = @{}
    }
}

function Get-PmcMetricsForDomain {
    param([string]$Domain)
    $reg = Get-PmcComputedRegistry
    if ($reg.ContainsKey($Domain)) { return $reg[$Domain] }
    return @{}
}

# Relation-derived fields
function Get-PmcRelationResolvers {
    param([string]$Domain,[string]$Relation)
    $map = @{}
    switch ($Domain) {
        'task' {
            if ($Relation -eq 'project') {
                $map['project_name'] = {
                    param($row,$data)
                    try { if ($row.PSObject.Properties['project']) { return [string]$row.project } } catch {}
                    return ''
                }
            }
        }
        'timelog' {
            if ($Relation -eq 'project') {
                $map['project_name'] = {
                    param($row,$data)
                    try { if ($row.PSObject.Properties['project']) { return [string]$row.project } } catch {}
                    return ''
                }
            }
            if ($Relation -eq 'task') {
                $map['task_text'] = {
                    param($row,$data)
                    try { if ($row.PSObject.Properties['taskId'] -and $row.taskId) { $t = ($data.tasks | Where-Object { $_ -ne $null -and $_.PSObject.Properties['id'] -and [int]$_.id -eq [int]$row.taskId } | Select-Object -First 1); if ($t -and $t.PSObject.Properties['text']) { return [string]$t.text } } } catch {}
                    return ''
                }
            }
        }
        default {}
    }
    return $map
}

#Export-ModuleMember -Function Get-PmcComputedRegistry, Get-PmcMetricsForDomain, Get-PmcRelationResolvers


# END FILE: ./module/Pmc.Strict/src/ComputedFields.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/Config.ps1
# SIZE: 5.52 KB
# MODIFIED: 2025-09-23 21:17:54
# ================================================================================

# Config provider indirection - now uses centralized state

function Set-PmcConfigProvider {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)] [scriptblock]$Get,
        [Parameter(Position=1)] [scriptblock]$Set
    )
    Set-PmcConfigProviders -Get $Get -Set $Set
}

function Get-PmcConfig {
    $providers = Get-PmcConfigProviders
    try { return & $providers.Get } catch { return @{} }
}

function Save-PmcConfig {
    param($cfg)
    $providers = Get-PmcConfigProviders
    if ($providers.Set) {
        try { & $providers.Set $cfg; return } catch {
            # Custom config provider failed - fall back to default
        }
    }
    # Default: write to pmc/config.json near module root
    try {
        $root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
        $path = Join-Path $root 'config.json'
        $cfg | ConvertTo-Json -Depth 10 | Set-Content -Path $path -Encoding UTF8
    } catch {
        # Default config file save failed - settings not persisted
    }
}

# Basic config schema validation and normalization
function Get-PmcDefaultConfig {
    return @{
        Display = @{ Theme = @{ Enabled=$true; Hex='#33aaff' }; Icons=@{ Mode='emoji' } }
        Debug = @{ Level=0; LogPath='debug.log'; MaxSize='10MB'; RedactSensitive=$true; IncludePerformance=$false }
        Security = @{ AllowedWritePaths=@('./','./reports/','./backups/'); MaxFileSize='100MB'; MaxMemoryUsage='500MB'; ScanForSensitiveData=$true; RequirePathWhitelist=$true; AuditAllFileOps=$true }
        Behavior = @{ StrictDataMode = $true; SafePathsStrict = $true; MaxBackups = 3; MaxUndoLevels = 10; WhatIf = $false }
    }
}

function Test-PmcConfigSchema {
    $cfg = Get-PmcConfig
    $errors = @(); $warnings=@()
    # Display.Theme.Hex
    try { $hex = [string]$cfg.Display.Theme.Hex; if (-not ($hex -match '^#?[0-9a-fA-F]{6}$')) { $warnings += 'Display.Theme.Hex invalid; using default' } } catch { $warnings += 'Display.Theme.Hex missing' }
    # Icons mode
    try { $mode = [string]$cfg.Display.Icons.Mode; if ($mode -notin @('ascii','emoji')) { $warnings += 'Display.Icons.Mode must be ascii|emoji' } } catch { $warnings += 'Display.Icons.Mode missing' }
    # Debug level
    try { $lvl = [int]$cfg.Debug.Level; if ($lvl -lt 0 -or $lvl -gt 3) { $warnings += 'Debug.Level out of range (0-3)' } } catch { $warnings += 'Debug.Level missing' }
    # Security paths
    try { if (-not ($cfg.Security.AllowedWritePaths -is [System.Collections.IEnumerable])) { $warnings += 'Security.AllowedWritePaths must be an array' } } catch { $warnings += 'Security.AllowedWritePaths missing' }
    return [pscustomobject]@{ IsValid = ($errors.Count -eq 0); Errors=$errors; Warnings=$warnings }
}

function Normalize-PmcConfig {
    $cfg = Get-PmcConfig
    $def = Get-PmcDefaultConfig
    foreach ($k in $def.Keys) {
        if (-not $cfg.ContainsKey($k)) { $cfg[$k] = $def[$k]; continue }
        foreach ($k2 in $def[$k].Keys) {
            if (-not $cfg[$k].ContainsKey($k2)) { $cfg[$k][$k2] = $def[$k][$k2] }
        }
    }
    # Normalize hex
    try { if ($cfg.Display.Theme.Hex -and -not ($cfg.Display.Theme.Hex.ToString().StartsWith('#'))) { $cfg.Display.Theme.Hex = '#' + $cfg.Display.Theme.Hex } } catch {}
    # Icons mode default
    try { if (-not $cfg.Display.Icons.Mode) { $cfg.Display.Icons.Mode = 'emoji' } } catch {}
    Save-PmcConfig $cfg
    return $cfg
}

function Validate-PmcConfig { param([PmcCommandContext]$Context)
    $result = Test-PmcConfigSchema
    if (-not $result.IsValid -or $result.Warnings.Count -gt 0) {
        Write-PmcStyled -Style 'Warning' -Text 'Config issues detected:'
        foreach ($w in $result.Warnings) { Write-PmcStyled -Style 'Muted' -Text ('  - ' + $w) }
    } else {
        Write-PmcStyled -Style 'Success' -Text 'Config looks good.'
    }
}

function Show-PmcConfig {
    param($Context)
    $cfg = Get-PmcConfig

    Write-PmcStyled -Style 'Header' -Text "`n⚙️ PMC CONFIGURATION`n"
    Write-PmcStyled -Style 'Subheader' -Text "Data Path:"
    Write-PmcStyled -Style 'Info' -Text "  $($cfg.Storage.DataPath)"
    Write-PmcStyled -Style 'Subheader' -Text "`nDisplay Settings:"
    Write-PmcStyled -Style 'Info' -Text "  Icons: $($cfg.Display.Icons.Mode)"
    Write-PmcStyled -Style 'Subheader' -Text "`nSecurity Level:"
    Write-PmcStyled -Style 'Info' -Text "  $($cfg.Security.Level)"
}

function Edit-PmcConfig {
    param($Context)
    Write-PmcStyled -Style 'Warning' -Text 'Config editing not yet implemented'
    Write-PmcStyled -Style 'Info' -Text 'Use: Show-PmcConfig to view current settings'
}

function Set-PmcConfigValue {
    param($Context)
    Write-PmcStyled -Style 'Warning' -Text 'Config value setting not yet implemented'
    Write-PmcStyled -Style 'Info' -Text 'Manual config editing required'
}

function Reload-PmcConfig {
    param($Context)
    # Force reload config
    $Script:PmcConfig = $null
    $cfg = Get-PmcConfig
    Write-PmcStyled -Style 'Success' -Text '✓ Config reloaded'
}

function Set-PmcIconMode {
    param($Context)

    $mode = 'emoji'
    if ($Context.FreeText.Count -gt 0) {
        $mode = $Context.FreeText[0].ToLower()
    }

    if ($mode -notin @('ascii', 'emoji')) {
        Write-PmcStyled -Style 'Error' -Text 'Icon mode must be: ascii or emoji'
        return
    }

    $cfg = Get-PmcConfig
    $cfg.Display.Icons.Mode = $mode
    Save-PmcConfig $cfg
    Write-PmcStyled -Style 'Success' -Text "✓ Icon mode set to: $mode"
}

# Export config functions
Export-ModuleMember -Function Get-PmcConfig, Validate-PmcConfig, Show-PmcConfig, Edit-PmcConfig, Set-PmcConfigValue, Reload-PmcConfig, Set-PmcIconMode


# END FILE: ./module/Pmc.Strict/src/Config.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/DataDisplay.ps1
# SIZE: 82.67 KB
# MODIFIED: 2025-09-24 04:53:48
# ================================================================================

# DataDisplay.ps1 - Universal data grid system for PMC
# Provides flexible, auto-sizing grid display for any domain combination

Set-StrictMode -Version Latest

class PmcGridRenderer {
    [hashtable] $ColumnConfig
    [int] $TerminalWidth
    [string[]] $Domains
    [hashtable] $Filters
    [hashtable] $ThemeConfig
    [hashtable] $ProjectLookup

    # NEW: Interactive navigation state
    [int] $SelectedRow = 0
    [int] $SelectedColumn = 0
    [string] $NavigationMode = "Row"  # Row, Cell, MultiSelect
    [bool] $Interactive = $false
    [bool] $ShowInternalHeader = $true
    [string] $TitleText = 'PMC Interactive Data Grid'
    [object[]] $CurrentData = @()
    [object[]] $AllData = @()
    [hashtable] $KeyBindings = @{}

    # NEW: Navigation mode flags
    [bool] $EditMode = $true          # true = Enter edits cells, false = Enter navigates/selects
    [scriptblock] $OnSelectCallback = $null  # Callback for navigation mode Enter

    # NEW: Editing state
    [bool] $InEditMode = $false
    [string] $EditingColumn = ""
    [string] $EditingValue = ""
    [hashtable] $EditCallbacks = @{}
    [bool] $LiveEditing = $false
    [scriptblock] $SaveCallback = $null

    # NEW: Inline editing state
    [bool] $InlineEditMode = $false
    [int] $EditCursorPos = 0
    [hashtable] $PendingEdits = @{}  # Store pending edits in memory until session completes
    [bool] $AllowSensitiveEdits = $false
    [string] $ConflictPolicy = 'InlineRelaxed'  # InlineRelaxed | Strict

    # NEW: Selection and multi-select
    [int[]] $SelectedRows = @()
    [bool] $MultiSelectMode = $false

    # NEW: Performance/diff rendering placeholders
    [hashtable] $RenderCache = @{}
    [bool] $DifferentialMode = $true

    # NEW: Simple live filtering state
    [string] $FilterQuery = ''
    [string] $LastErrorMessage = ''

    [string] GetPrimaryDomain() {
        if ($this.Domains -and @($this.Domains).Count -gt 0) { return [string]$this.Domains[0] }
        return ''
    }

    [hashtable] GetFieldSchema([string]$ColumnName) {
        $dom = $this.GetPrimaryDomain()
        if ($dom) { return (Get-PmcFieldSchema -Domain $dom -Field $ColumnName) }
        return $null
    }

    [string] GetFieldHint([string]$ColumnName) {
        $sch = $this.GetFieldSchema($ColumnName)
        if ($sch -and $sch.ContainsKey('Hint')) { return [string]$sch.Hint }
        return ''
    }

    [string] NormalizeField([string]$ColumnName, [string]$Value) {
        $sch = $this.GetFieldSchema($ColumnName)
        if ($sch -and $sch.ContainsKey('Normalize') -and $sch.Normalize) { return (& $sch.Normalize $Value) }
        return $Value
    }

    [void] ValidateField([string]$ColumnName, [string]$Value) {
        $sch = $this.GetFieldSchema($ColumnName)
        if ($sch -and $sch.ContainsKey('Validate') -and $sch.Validate) { & $sch.Validate $Value | Out-Null }
    }

    # NEW: Sorting state
    [string] $SortColumn = ''
    [string] $SortDirection = 'None'  # None | Asc | Desc

    # NEW: Saved views map
    [hashtable] $SavedViews = @{}

    # NEW: Differential rendering cache/state
    [string[]] $LastLines = @()

    # NEW: Praxis frame renderer for proper double buffering
    [object] $FrameRenderer = $null
    [bool] $HasInitialRender = $false
    [int] $RefreshIntervalMs = 0
    [datetime] $LastRefreshAt = [datetime]::MinValue

    # NEW: Layout and scrolling
    [int] $WindowHeight = 0
    [int] $HeaderLines = 4   # Title, border, header, separator
    [int] $ScrollOffset = 0

    PmcGridRenderer([hashtable]$Columns, [string[]]$Domains, [hashtable]$Filters) {
        $this.ColumnConfig = $Columns
        $this.Domains = $Domains
        $this.Filters = $Filters
        $this.ThemeConfig = $this.InitializeTheme(@{})
        $this.TerminalWidth = $this.GetTerminalWidth()
        $this.WindowHeight = $this.GetTerminalHeight()
        $this.ProjectLookup = $this.LoadProjectLookup()
        $this.InitializeKeyBindings()
        $this.LoadSavedViews()

        # Initialize Praxis frame renderer for proper double buffering
        $this.FrameRenderer = [PraxisFrameRenderer]::new()
    }

    [hashtable] InitializeTheme([hashtable]$UserTheme) {
        # Get PMC's existing style system
        $pmcStyles = Get-PmcState -Section 'Display' -Key 'Styles'

        # Default grid theme using PMC style tokens
        $defaultTheme = @{
            Default = @{
                Style = "Body"  # Uses PMC's Body style token
            }
            Columns = @{}
            Rows = @{
                Header = @{ Style = "Header" }      # Uses PMC's Header style
                Separator = @{ Style = "Border" }   # Uses PMC's Border style
            }
            Cells = @()
        }

        # Merge user theme with defaults (deep merge)
        if ($UserTheme.PSObject.Properties['Default']) {
            $defaultTheme.Default = $this.MergeStyles($defaultTheme.Default, $UserTheme.Default)
        }
        if ($UserTheme.PSObject.Properties['Columns']) {
            foreach ($col in $UserTheme.Columns.Keys) {
                $defaultTheme.Columns[$col] = $UserTheme.Columns[$col]
            }
        }
        if ($UserTheme.PSObject.Properties['Rows']) {
            foreach ($row in $UserTheme.Rows.Keys) {
                $defaultTheme.Rows[$row] = $this.MergeStyles($defaultTheme.Rows[$row], $UserTheme.Rows[$row])
            }
        }
        if ($UserTheme.PSObject.Properties['Cells']) {
            $defaultTheme.Cells = $UserTheme.Cells
        }

        return $defaultTheme
    }

    [hashtable] MergeStyles([hashtable]$Base, [hashtable]$Override) {
        $merged = @{}
        if ($Base) {
            foreach ($key in $Base.Keys) { $merged[$key] = $Base[$key] }
        }
        if ($Override) {
            foreach ($key in $Override.Keys) { $merged[$key] = $Override[$key] }
        }
        return $merged
    }

    [hashtable] GetCellTheme([object]$Item, [string]$ColumnName, [int]$RowIndex, [bool]$IsHeader) {
        # Start with default theme
        $cellTheme = $this.ThemeConfig.Default.Clone()

        # Apply column theme
        if ($ColumnName -and $this.ThemeConfig.Columns.PSObject.Properties[$ColumnName]) {
            $cellTheme = $this.MergeStyles($cellTheme, $this.ThemeConfig.Columns[$ColumnName])
        }

        # Apply row theme
        if ($IsHeader -and $this.ThemeConfig.Rows.PSObject.Properties['Header']) {
            $cellTheme = $this.MergeStyles($cellTheme, $this.ThemeConfig.Rows.Header)
        }

        # Apply cell-specific themes (conditional)
        if (-not $IsHeader -and $this.ThemeConfig.Cells) {
            foreach ($cellRule in $this.ThemeConfig.Cells) {
                # Check if rule applies to this cell
                if ($cellRule.PSObject.Properties['Column'] -and $cellRule.Column -ne $ColumnName) {
                    continue  # Rule is column-specific and doesn't match
                }

                $applies = $true
                if ($cellRule.PSObject.Properties['Condition'] -and $cellRule.Condition) {
                    try {
                        $applies = & $cellRule.Condition $Item
                    } catch {
                        $applies = $false
                    }
                }

                if ($applies -and $cellRule.PSObject.Properties['Style']) {
                    $cellTheme = $this.MergeStyles($cellTheme, $cellRule.Style)
                }
            }
        }

        # Consult global cell style hook if available
        if (-not $IsHeader) {
            $hook = Get-Command -Name 'Get-PmcCellStyle' -ErrorAction SilentlyContinue
            if ($hook) {
                $val = $null
                if ($Item -ne $null -and $ColumnName) {
                    $val = $this.GetItemValue($Item, $ColumnName)
                }
                $ext = Get-PmcCellStyle -RowData $Item -Column $ColumnName -Value $val
                if ($ext -and ($ext -is [hashtable])) { $cellTheme = $this.MergeStyles($cellTheme, $ext) }
            }
        }

        return $cellTheme
    }

    [string] ApplyTheme([string]$Text, [hashtable]$CellTheme) {
        # If we have a PMC style token, use Write-PmcStyled approach
        if ($CellTheme.PSObject.Properties['Style']) {
            $style = Get-PmcStyle $CellTheme.Style
            if ($style -and $style.PSObject.Properties['Fg']) {
                # Use PMC's styling but return the ANSI codes directly for grid integration
                return $this.ConvertPmcStyleToAnsi($Text, $style, $CellTheme)
            }
        }

        # Direct color specification (RGB, Hex, Named)
        $fgCode = ""
        $bgCode = ""

        # Handle foreground color
        if ($CellTheme.PSObject.Properties['Foreground'] -or $CellTheme.PSObject.Properties['Fg']) {
            $fg = if ($CellTheme.Foreground) { $CellTheme.Foreground } else { $CellTheme.Fg }
            $fgCode = $this.GetColorCode($fg, $false)
        }

        # Handle background color
        if ($CellTheme.PSObject.Properties['Background'] -or $CellTheme.PSObject.Properties['Bg']) {
            $bg = if ($CellTheme.Background) { $CellTheme.Background } else { $CellTheme.Bg }
            $bgCode = $this.GetColorCode($bg, $true)
        }

        if ($fgCode -or $bgCode) {
            $pre = "$fgCode$bgCode"
            if ($CellTheme.PSObject.Properties['Bold'] -and $CellTheme.Bold) { $pre += [PmcVT]::Bold() }
            return "$pre$Text" + [PmcVT]::Reset()
        }

        return $Text
    }

    [string] ConvertPmcStyleToAnsi([string]$Text, [hashtable]$PmcStyle, [hashtable]$CellTheme) {
        $codes = ""

        # Convert PMC style to ANSI codes (robust hashtable access)
        $fgVal = $null; $bgVal = $null; $bold = $false
        if ($PmcStyle) {
            if (($PmcStyle -is [hashtable]) -and $PmcStyle.ContainsKey('Fg')) { $fgVal = $PmcStyle['Fg'] }
            elseif ($PmcStyle.PSObject -and $PmcStyle.PSObject.Properties['Fg']) { $fgVal = $PmcStyle.Fg }
            if (($PmcStyle -is [hashtable]) -and $PmcStyle.ContainsKey('Bg')) { $bgVal = $PmcStyle['Bg'] }
            elseif ($PmcStyle.PSObject -and $PmcStyle.PSObject.Properties['Bg']) { $bgVal = $PmcStyle.Bg }
            if (($PmcStyle -is [hashtable]) -and $PmcStyle.ContainsKey('Bold')) { if ($PmcStyle['Bold']) { $bold = $true } }
            elseif ($PmcStyle.PSObject -and $PmcStyle.PSObject.Properties['Bold']) { if ($PmcStyle.Bold) { $bold = $true } }
        }
        if ($fgVal) { $codes += $this.GetColorCode([string]$fgVal, $false) }
        if ($bgVal) { $codes += $this.GetColorCode([string]$bgVal, $true) }

        # Apply any additional cell-specific overrides
        if ($CellTheme) {
            $cellFg = $null; $cellBg = $null; $cellBold = $false
            if (($CellTheme -is [hashtable]) -and $CellTheme.ContainsKey('Fg')) { $cellFg = $CellTheme['Fg'] }
            elseif ($CellTheme.PSObject -and $CellTheme.PSObject.Properties['Fg']) { $cellFg = $CellTheme.Fg }
            if (($CellTheme -is [hashtable]) -and $CellTheme.ContainsKey('Bg')) { $cellBg = $CellTheme['Bg'] }
            elseif ($CellTheme.PSObject -and $CellTheme.PSObject.Properties['Bg']) { $cellBg = $CellTheme.Bg }
            if (($CellTheme -is [hashtable]) -and $CellTheme.ContainsKey('Bold')) { if ($CellTheme['Bold']) { $cellBold = $true } }
            elseif ($CellTheme.PSObject -and $CellTheme.PSObject.Properties['Bold']) { if ($CellTheme.Bold) { $cellBold = $true } }
            if ($cellFg) { $codes += $this.GetColorCode([string]$cellFg, $false) }
            if ($cellBg) { $codes += $this.GetColorCode([string]$cellBg, $true) }
            if ($cellBold) { $bold = $true }
        }

        # Bold emphasis if requested
        if ($bold) { $codes += [PmcVT]::Bold() }

        if ($codes) {
            return "$codes$Text" + [PmcVT]::Reset()
        }
        return $Text
    }

    [string] GetColorCode([string]$Color, [bool]$IsBackground) {
        if (-not $Color) { return "" }

        # Handle hex colors (#RRGGBB or #RGB)
        if ($Color -match '^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{3})$') {
            $rgb = ConvertFrom-PmcHex $Color
            if ($rgb) {
                if ($IsBackground) {
                    return [PmcVT]::BgRGB($rgb.R, $rgb.G, $rgb.B)
                } else {
                    return [PmcVT]::FgRGB($rgb.R, $rgb.G, $rgb.B)
                }
            }
        }

        # Handle RGB values (255,128,64)
        if ($Color -match '^(\d{1,3}),(\d{1,3}),(\d{1,3})$') {
            $r = [int]$Matches[1]
            $g = [int]$Matches[2]
            $b = [int]$Matches[3]
            if ($r -le 255 -and $g -le 255 -and $b -le 255) {
                if ($IsBackground) {
                    return [PmcVT]::BgRGB($r, $g, $b)
                } else {
                    return [PmcVT]::FgRGB($r, $g, $b)
                }
            }
        }

        # Handle named colors (fallback to standard ANSI)
        $ansiCode = if ($IsBackground) { 40 } else { 30 }
        switch ($Color.ToLower()) {
            "black" { $ansiCode += 0 }
            "red" { $ansiCode += 1 }
            "green" { $ansiCode += 2 }
            "yellow" { $ansiCode += 3 }
            "blue" { $ansiCode += 4 }
            "magenta" { $ansiCode += 5 }
            "cyan" { $ansiCode += 6 }
            "white" { $ansiCode += 7 }
            "gray" { $ansiCode = if ($IsBackground) { 100 } else { 90 } }
            "brightred" { $ansiCode = if ($IsBackground) { 101 } else { 91 } }
            "brightgreen" { $ansiCode = if ($IsBackground) { 102 } else { 92 } }
            "brightyellow" { $ansiCode = if ($IsBackground) { 103 } else { 93 } }
            "brightblue" { $ansiCode = if ($IsBackground) { 104 } else { 94 } }
            "brightmagenta" { $ansiCode = if ($IsBackground) { 105 } else { 95 } }
            "brightcyan" { $ansiCode = if ($IsBackground) { 106 } else { 96 } }
            "brightwhite" { $ansiCode = if ($IsBackground) { 107 } else { 97 } }
            default { return "" }
        }

        return "`e[${ansiCode}m"
    }

    [int] GetTerminalWidth() {
        return [PmcTerminalService]::GetWidth()
    }

    [int] GetTerminalHeight() {
        return [PmcTerminalService]::GetHeight()
    }

    [hashtable] GetTerminalBounds() {
        return [PmcTerminalService]::GetDimensions()
    }

    [bool] ValidateScreenBounds([string]$Content, [int]$MaxWidth = 0, [int]$MaxHeight = 0) {
        return [PmcTerminalService]::ValidateContent($Content, $MaxWidth, $MaxHeight)
    }

    [string] EnforceScreenBounds([string]$Content, [int]$MaxWidth = 0, [int]$MaxHeight = 0) {
        return [PmcTerminalService]::EnforceContentBounds($Content, $MaxWidth, $MaxHeight)
    }

    [hashtable] LoadProjectLookup() {
        # Load project data to resolve project names from IDs
        $lookup = @{}
        try {
            $data = Get-PmcDataProvider 'Storage'
            if ($data -and $data.GetData) {
                $projectData = $data.GetData()
                if ($projectData.projects) {
                    foreach ($project in $projectData.projects) {
                        if ($project.name) {
                            $lookup[$project.name] = $project.name
                            # Also map any aliases if they exist
                            if ($project.PSObject.Properties['aliases'] -and $project.aliases) {
                                foreach ($alias in $project.aliases) {
                                    $lookup[$alias] = $project.name
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            Write-PmcDebug -Level 2 -Category "DataDisplay" -Message "Failed to load project lookup" -Data @{ Error = $_.Exception.Message }
        }
        return $lookup
    }

    [void] InitializeKeyBindings() {
        $this.KeyBindings = @{
            # Navigation
            "UpArrow"    = { $this.MoveUp() }
            "DownArrow"  = { $this.MoveDown() }
            "LeftArrow"  = { $this.MoveLeft() }
            "RightArrow" = { $this.MoveRight() }
            "PageUp"     = { $this.PageUp() }
            "PageDown"   = { $this.PageDown() }
            "Home"       = { $this.MoveToStart() }
            "End"        = { $this.MoveToEnd() }
            "Ctrl+LeftArrow"  = { $this.MoveToColumnStart() }
            "Ctrl+RightArrow" = { $this.MoveToColumnEnd() }

            # Selection
            "Shift+UpArrow"   = { $this.ExtendSelectionUp() }
            "Shift+DownArrow" = { $this.ExtendSelectionDown() }
            "Ctrl+A"          = { $this.SelectAll() }

            # Editing/Navigation
            "Enter"      = { $this.HandleEnterKey() }
            "F2"         = { $this.StartCellEdit() }
            "Escape"     = { if ($this.InEditMode -or $this.InlineEditMode) { $this.CancelEdit() } else { $this.ExitInteractive() } }
            "Delete"     = { $this.DeleteSelected() }

            # Actions
            "Ctrl+S"     = { $this.SaveChanges() }
            "Ctrl+Z"     = { $this.Undo() }
            "Ctrl+R"     = { $this.RefreshData() }
            "F5"         = { $this.RefreshData() }
            "Ctrl+F"     = { $this.PromptFilter() }
            # Quick open filter/search with '/'
            "Oem2"       = { $this.PromptFilter() }  # '/' key on most layouts
            # Sorting
            "F3"         = { $this.ToggleSortCurrentColumn() }
            # Saved views
            "F6"         = { $this.PromptSaveView() }
            "F7"         = { $this.PromptLoadView() }
            "F8"         = { $this.ListSavedViews() }

            # Mode switching
            "Tab"        = { $this.SwitchNavigationMode($false) }
            "Shift+Tab"  = { $this.SwitchNavigationMode($true) }

            # Exit
            "Q"          = { $this.ExitInteractive() }
            "Ctrl+C"     = { $this.ExitInteractive() }
        }
    }

    # Navigation methods
    [void] MoveUp() {
        if (@($this.CurrentData).Count -eq 0) { return }
        if ($this.SelectedRow -gt 0) {
            $oldRow = $this.SelectedRow
            $this.SelectedRow--
            Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message 'MoveUp navigation' -Data @{ From = $oldRow; To = $this.SelectedRow; DataCount = @($this.CurrentData).Count }
            $this.EnsureInView()
            $this.RefreshDisplay()
        }
    }

    [void] MoveDown() {
        if (@($this.CurrentData).Count -eq 0) { return }
        if ($this.SelectedRow -lt (@($this.CurrentData).Count - 1)) {
            $oldRow = $this.SelectedRow
            $this.SelectedRow++
            Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message 'MoveDown navigation' -Data @{ From = $oldRow; To = $this.SelectedRow; DataCount = @($this.CurrentData).Count }
            $this.EnsureInView()
            $this.RefreshDisplay()
        }
    }

    [void] MoveLeft() {
        if ($this.NavigationMode -eq "Cell") {
            $columns = @($this.ColumnConfig.Keys)
            if ($this.SelectedColumn -gt 0) {
                $this.SelectedColumn--
                $this.RefreshDisplay()
            }
        }
    }

    [void] MoveRight() {
        if ($this.NavigationMode -eq "Cell") {
            $columns = @($this.ColumnConfig.Keys)
            if ($this.SelectedColumn -lt ($columns.Count - 1)) {
                $this.SelectedColumn++
                $this.RefreshDisplay()
            }
        }
    }

    [void] PageUp() {
        if (@($this.CurrentData).Count -eq 0) { return }
        try {
            $winHeight = [PmcTerminalService]::GetHeight()
            $pageSize = [Math]::Max(1, $winHeight - ($this.HeaderLines + 2))
        } catch {
            $pageSize = 10  # Fallback page size
        }
        $this.SelectedRow = [Math]::Max(0, $this.SelectedRow - $pageSize)
        $this.EnsureInView()
        $this.RefreshDisplay()
    }

    [void] PageDown() {
        if (@($this.CurrentData).Count -eq 0) { return }
        try {
            $winHeight = [PmcTerminalService]::GetHeight()
            $pageSize = [Math]::Max(1, $winHeight - ($this.HeaderLines + 2))
        } catch {
            $pageSize = 10  # Fallback page size
        }
        $this.SelectedRow = [Math]::Min(@($this.CurrentData).Count - 1, $this.SelectedRow + $pageSize)
        $this.EnsureInView()
        $this.RefreshDisplay()
    }

    [void] MoveToStart() {
        $this.SelectedRow = 0
        $this.ScrollOffset = 0
        $this.RefreshDisplay()
    }

    [void] MoveToEnd() {
        if (@($this.CurrentData).Count -gt 0) {
            $this.SelectedRow = @($this.CurrentData).Count - 1
            $this.EnsureInView()
            $this.RefreshDisplay()
        }
    }

    # Selection methods
    [void] ExtendSelectionUp() {
        $this.MultiSelectMode = $true
        if (@($this.SelectedRows).Count -eq 0) {
            $this.SelectedRows = @($this.SelectedRow)
        }
        if ($this.SelectedRow -gt 0) {
            $this.SelectedRow--
            if ($this.SelectedRows -notcontains $this.SelectedRow) {
                $this.SelectedRows += $this.SelectedRow
            }
            $this.RefreshDisplay()
        }
    }

    [void] ExtendSelectionDown() {
        $this.MultiSelectMode = $true
        if (@($this.SelectedRows).Count -eq 0) {
            $this.SelectedRows = @($this.SelectedRow)
        }
        if ($this.SelectedRow -lt (@($this.CurrentData).Count - 1)) {
            $this.SelectedRow++
            if ($this.SelectedRows -notcontains $this.SelectedRow) {
                $this.SelectedRows += $this.SelectedRow
            }
            $this.RefreshDisplay()
        }
    }

    [void] SelectAll() {
        $this.MultiSelectMode = $true
        $this.SelectedRows = @(0..(@($this.CurrentData).Count - 1))
        $this.RefreshDisplay()
    }

    # Editing methods
    # NEW: Handle Enter key based on mode
    [void] HandleEnterKey() {
        Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message 'HandleEnterKey' -Data @{ EditMode=$this.EditMode; HasCallback=($this.OnSelectCallback -ne $null) }

        if ($this.EditMode) {
            # Edit mode: Start cell editing (original behavior)
            $this.StartCellEdit()
        } else {
            # Navigation mode: Execute selection callback or exit
            if ($this.OnSelectCallback -ne $null) {
                Write-PmcDebug -Level 2 -Category 'DataDisplay' -Message 'Executing OnSelectCallback'
                try {
                    $selectedItem = if (@($this.CurrentData).Count -gt 0 -and $this.SelectedRow -lt @($this.CurrentData).Count) {
                        $this.CurrentData[$this.SelectedRow]
                    } else {
                        $null
                    }
                    & $this.OnSelectCallback $selectedItem $this.SelectedRow
                } catch {
                    Write-PmcDebug -Level 1 -Category 'DataDisplay' -Message 'OnSelectCallback error' -Data @{ Error = $_.Exception.Message }
                }
            } else {
                # No callback, exit interactive mode
                Write-PmcDebug -Level 2 -Category 'DataDisplay' -Message 'No callback, exiting interactive mode'
                $this.Interactive = $false
            }
        }
    }

    [void] StartCellEdit() {
        Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message 'StartCellEdit' -Data @{ Nav=$this.NavigationMode; Row=$this.SelectedRow; Count=@($this.CurrentData).Count }

        if (@($this.CurrentData).Count -eq 0 -or $this.SelectedRow -ge @($this.CurrentData).Count) {
            Write-PmcDebug -Level 2 -Category 'DataDisplay' -Message 'StartCellEdit: No data or invalid row'
            return
        }

        $columns = @($this.ColumnConfig.Keys)
        $editableColumns = $this.GetEditableColumns()
        $columnName = $null

        # Determine which column to edit based on navigation mode
        if ($this.NavigationMode -eq "Row") {
            # Start with the first editable column (defaults generally to 'text')
            if (@($editableColumns).Count -gt 0) { $columnName = $editableColumns[0] }
            elseif (@($columns).Count -gt 0) { $columnName = $columns[0] }
        }
        elseif ($this.NavigationMode -eq "Cell" -and $this.SelectedColumn -lt @($columns).Count) {
            $tryCol = $columns[$this.SelectedColumn]
            if ($this.IsColumnEditable($tryCol)) { $columnName = $tryCol }
            else {
                # Find the next editable column from the current position (wrapping)
                for ($i = 1; $i -le @($columns).Count; $i++) {
                    $idx = ($this.SelectedColumn + $i) % @($columns).Count
                    $c = $columns[$idx]
                    if ($this.IsColumnEditable($c)) { $columnName = $c; break }
                }
            }
        }

        if ($columnName) {
            $currentItem = $this.CurrentData[$this.SelectedRow]
            Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message 'Editing item' -Data $currentItem
            if ($this.PendingEdits.ContainsKey($columnName)) { $currentValue = [string]$this.PendingEdits[$columnName] }
            else { $currentValue = $this.GetItemValue($currentItem, $columnName) }

            $this.InEditMode = $true
            $this.EditingColumn = $columnName
            $this.EditingValue = $currentValue
            Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message ("Starting edit for column '{0}'" -f $columnName) -Data @{ Value=$currentValue }
            $this.ShowEditDialog($columnName, $currentValue)
        }
        else {
            Write-PmcDebug -Level 2 -Category 'DataDisplay' -Message 'StartCellEdit: Invalid mode or column'
        }
    }

    [void] ShowEditDialog([string]$ColumnName, [string]$CurrentValue) {
        Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message ("ShowEditDialog: start '{0}'" -f $ColumnName)

        # Start inline editing mode
        $this.EditingValue = $CurrentValue
        $this.EditCursorPos = $CurrentValue.Length
        $this.InlineEditMode = $true
        $this.LastErrorMessage = ''

        while ($true) {
            # Redraw with edit indicator and get new value through key input
            $this.RefreshDisplay()
            $newVal = $this.HandleInlineEdit()

            if ($null -eq $newVal) {
                # Escape or navigation-only path: discard staged and exit dialog
                $this.CancelEdit()
                return
            }

            # Normalize then stage current column value
            try {
                $normalized = $this.NormalizeField($ColumnName, [string]$newVal)
            } catch {
                $this.LastErrorMessage = $_.Exception.Message
                # Re-enter editing on same column with user input intact
                $this.EditingValue = [string]$newVal
                $this.EditCursorPos = $this.EditingValue.Length
                $this.InlineEditMode = $true
                continue
            }
            $this.PendingEdits[$ColumnName] = [string]$normalized

            # Validate all staged edits
            $validationError = $null
            foreach ($col in @($this.PendingEdits.Keys)) {
                $val = [string]$this.PendingEdits[$col]
                if ($this.EditCallbacks.ContainsKey($col)) {
                    $ok = & $this.EditCallbacks[$col] $val
                    if (-not $ok) { $validationError = "Invalid value for $col"; break }
                } else {
                    try {
                        $this.ValidateField($col, $val)
                    } catch {
                        $validationError = $_.Exception.Message
                        break
                    }
                }
            }

            if ($validationError) {
                $this.LastErrorMessage = $validationError
                # Re-enter editing on current column
                $this.EditingValue = [string]$normalized
                $this.EditCursorPos = $this.EditingValue.Length
                $this.InlineEditMode = $true
                continue
            }

            # Apply batch and exit
            try {
                $this.ApplyPendingEdits()
                $this.LastErrorMessage = ''
                $this.CancelEdit()
                return
            } catch {
                $this.LastErrorMessage = "Failed to save: $($_.Exception.Message)"
                # Keep editing to allow correction
                $this.InlineEditMode = $true
            }
        }
    }

    # Per-field normalization moved to FieldSchemas

    [void] CancelEdit() {
        $this.InEditMode = $false
        $this.InlineEditMode = $false
        $this.EditingColumn = ""
        $this.EditingValue = ""
        # Clear pending edits without saving
        $this.PendingEdits.Clear()
        $this.RefreshDisplay()
    }

    [void] ApplyPendingEdits() {
        Write-PmcDebug -Level 2 -Category 'DataDisplay' -Message 'ApplyPendingEdits' -Data @{ Columns = @($this.PendingEdits.Keys) }
        foreach ($column in $this.PendingEdits.Keys) {
            $value = $this.PendingEdits[$column]
            try {
                # Inline editing: skip value conflict checks (opt-in strict policy can be implemented per-view later)
                $this.ApplyCellEdit($this.SelectedRow, $column, $value, $null)
                Write-PmcDebug -Level 2 -Category 'DataDisplay' -Message ("Applied edit for '{0}'" -f $column) -Data @{ Value=$value }
            } catch {
                Write-PmcDebug -Level 1 -Category 'DataDisplay' -Message ("Failed to apply edit for '{0}'" -f $column) -Data @{ Error = $_.ToString() }
            }
        }
        $this.PendingEdits.Clear()
    }

    [void] EnableInlineEditing([string]$Column, [scriptblock]$Validator) {
        if (-not $Column) { throw "EnableInlineEditing: Column is required" }
        $this.EditCallbacks[$Column] = $Validator
    }

    [void] ApplyCellEdit([int]$RowIndex, [string]$ColumnName, [string]$NewValue, [string]$OriginalValue) {
        if ($RowIndex -lt 0 -or $RowIndex -ge @($this.CurrentData).Count) { throw "Invalid row index" }
        $item = $this.CurrentData[$RowIndex]
        if (-not $item) { throw "No item at row $RowIndex" }

        # Wizard/form editing: in-memory only, no persistence
        $primaryDomain = $this.GetPrimaryDomain()
        if ($primaryDomain -eq 'wizard') {
            if ($item.PSObject.Properties[$ColumnName]) { $item.$ColumnName = [string]$NewValue }
            else { $item | Add-Member -NotePropertyName $ColumnName -NotePropertyValue ([string]$NewValue) -Force }
            return
        }

        # Update in persistent store by ID when available
        $id = $null
        if ($item.PSObject.Properties['id']) { $id = [int]$item.id }
        if ($null -eq $id) { throw "Cannot edit item without id" }

        $root = Get-PmcDataAlias
        if (-not $root -or -not $root.tasks) { throw "Data store not available" }

        $target = $root.tasks | Where-Object { $_ -ne $null -and $_.id -eq $id } | Select-Object -First 1
        if (-not $target) { throw "Item #$id not found" }

        # Optional optimistic concurrency check
        if ($OriginalValue -ne $null) {
            $currentOnDisk = ''
            if ($target.PSObject.Properties[$ColumnName]) { $currentOnDisk = [string]$target.$ColumnName }
            if ($currentOnDisk -ne $OriginalValue) {
                throw ("Conflict: {0} changed externally (was '{1}', now '{2}')" -f $ColumnName, $OriginalValue, $currentOnDisk)
            }
        }

        switch ($ColumnName) {
            'text'     { $target.text = [string]$NewValue }
            'project'  {
                $dataAll = Get-PmcDataAlias
                $resolved = Resolve-Project -Data $dataAll -Name ([string]$NewValue)
                if (-not $resolved) { throw ("Unknown project '{0}'" -f $NewValue) }
                $target.project = [string]$resolved.name
            }
            'priority' { $target.priority = [int]$NewValue }
            'due'      { $target.due = [string]$NewValue }
            default    { $target | Add-Member -NotePropertyName $ColumnName -NotePropertyValue $NewValue -Force }
        }

        Save-PmcData -data $root -Action "edit:$ColumnName"

        # Reflect changes in current view item as well
        if ($item.PSObject.Properties[$ColumnName]) { $item.$ColumnName = $NewValue }
        else { $item | Add-Member -NotePropertyName $ColumnName -NotePropertyValue $NewValue -Force }
    }

    [void] SaveChanges() {
        if ($this.SaveCallback) {
            & $this.SaveCallback @{}
            return
        }
        throw "No pending changes or SaveCallback configured"
    }

    [void] DeleteSelected() {
        # Only support deleting tasks for now
        if (-not ($this.Domains -contains 'task')) { throw "Delete not supported for this view" }
        if (@($this.CurrentData).Count -eq 0) { return }
        $rows = @()
        if ($this.MultiSelectMode -and @($this.SelectedRows).Count -gt 0) { $rows = @($this.SelectedRows) } else { $rows = @($this.SelectedRow) }
        $ids = @()
        foreach ($ri in $rows) {
            if ($ri -ge 0 -and $ri -lt @($this.CurrentData).Count) {
                $it = $this.CurrentData[$ri]
                if ($it -and $it.PSObject.Properties['id']) { $ids += [int]$it.id }
            }
        }
        if (@($ids).Count -eq 0) { return }

        $root = Get-PmcDataAlias
        if (-not $root -or -not $root.tasks) { throw "Data store not available" }
        $root.tasks = @($root.tasks | Where-Object { $_ -eq $null -or ($_.PSObject.Properties['id'] -and (-not ($ids -contains [int]$_.id))) })
        Save-PmcData -data $root -Action 'delete:task'
        $this.RefreshData()
    }

    [void] Undo() {
        if (Get-Command Invoke-PmcUndo -ErrorAction SilentlyContinue) {
            Invoke-PmcUndo | Out-Null
            $this.RefreshData()
            return
        }
        throw "Undo not available"
    }

    [void] PromptFilter() {
        $row = [PmcTerminalService]::GetHeight() - 2
        Write-Host ([PmcVT]::MoveTo(0, $row) + [PmcVT]::ClearLine())
        Write-Host -NoNewline "Filter (text or re:/pattern/): "
        $q = Read-Host
        if ($null -ne $q) { $this.FilterQuery = [string]$q; $this.ApplyFilter(); $this.RefreshDisplay() }
    }

    [void] RefreshData() {
        # Reload data from PMC and refresh display
        if ($this.Interactive) {
            $newData = Get-PmcFilteredData -Domains $this.Domains -Filters $this.Filters
            $this.AllData = $newData
            $this.ApplyFilter()
            $this.RefreshDisplay()
        }
    }

    [void] SwitchNavigationMode([bool]$Reverse = $false) {
        if ($Reverse) {
            $this.NavigationMode = if ($this.NavigationMode -eq "Row") { "Cell" } else { "Row" }
        } else {
            $this.NavigationMode = if ($this.NavigationMode -eq "Cell") { "Row" } else { "Cell" }
        }
        $this.RefreshDisplay()
    }

    [string] HandleInlineEdit() {
        Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message 'HandleInlineEdit: start'

        $editBuffer = $this.EditingValue
        $cursorPos = $this.EditCursorPos

        while ($this.InlineEditMode) {
            try {
                if ([Console]::KeyAvailable) {
                $key = [Console]::ReadKey($true)
                $keyName = $key.Key.ToString()

                Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message 'Inline edit key' -Data @{ Key=$keyName; Char=[int]$key.KeyChar }

                switch ($key.Key) {
                    "Enter" {
                        Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message 'Enter: save current field and exit edit mode' -Data @{ Value=$editBuffer }

                        # Store current field edit in pending edits
                        $this.PendingEdits[$this.EditingColumn] = $editBuffer
                        Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message ("Staged final edit for '{0}' on Enter" -f $this.EditingColumn) -Data @{ Value=$editBuffer }

                        # Exit edit mode and signal to save all pending edits
                        $this.InlineEditMode = $false
                        return $editBuffer
                    }
                    "Escape" {
                        Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message 'Inline edit cancelled'
                        $this.InlineEditMode = $false
                        return $null
                    }
                    "Tab" {
                        # Check for Shift modifier
                        if ($key.Modifiers -band [ConsoleModifiers]::Shift) {
                            # Shift+Tab moves to previous column
                            Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message 'Shift+Tab: previous column'

                            # Store current edit in memory instead of saving immediately
                            $this.PendingEdits[$this.EditingColumn] = $editBuffer
                            Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message ("Staged edit for '{0}'" -f $this.EditingColumn) -Data @{ Value=$editBuffer }

                            # Move to previous column
                            $this.MoveToPreviousColumnAndEdit()
                            return $null
                        } else {
                            # Tab moves to next column and continues editing
                            Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message 'Tab: next column'

                            # Store current edit in memory instead of saving immediately
                            $this.PendingEdits[$this.EditingColumn] = $editBuffer
                            Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message ("Staged edit for '{0}'" -f $this.EditingColumn) -Data @{ Value=$editBuffer }

                            # Move to next column
                            $this.MoveToNextColumnAndEdit()
                            return $null  # Don't return the value, we're continuing to edit
                        }
                    }
                    "LeftArrow" {
                        if ($cursorPos -gt 0) {
                            $cursorPos--
                            $this.EditCursorPos = $cursorPos
                            $this.RefreshDisplay()
                        }
                    }
                    "RightArrow" {
                        if ($cursorPos -lt $editBuffer.Length) {
                            $cursorPos++
                            $this.EditCursorPos = $cursorPos
                            $this.RefreshDisplay()
                        }
                    }
                    "Home" {
                        $cursorPos = 0
                        $this.EditCursorPos = $cursorPos
                        $this.RefreshDisplay()
                    }
                    "End" {
                        $cursorPos = $editBuffer.Length
                        $this.EditCursorPos = $cursorPos
                        $this.RefreshDisplay()
                    }
                    "Backspace" {
                        if ($cursorPos -gt 0) {
                            $editBuffer = $editBuffer.Remove($cursorPos - 1, 1)
                            $cursorPos--
                            $this.EditingValue = $editBuffer
                            $this.EditCursorPos = $cursorPos
                            $this.RefreshDisplay()
                        }
                    }
                    "Delete" {
                        if ($cursorPos -lt $editBuffer.Length) {
                            $editBuffer = $editBuffer.Remove($cursorPos, 1)
                            $this.EditingValue = $editBuffer
                            $this.RefreshDisplay()
                        }
                    }
                    default {
                        # Add printable characters at cursor position
                        if ($key.KeyChar -and [int]$key.KeyChar -ge 32 -and [int]$key.KeyChar -le 126) {
                            $editBuffer = $editBuffer.Insert($cursorPos, $key.KeyChar)
                            $cursorPos++
                            $this.EditingValue = $editBuffer
                            $this.EditCursorPos = $cursorPos
                            $this.RefreshDisplay()
                        }
                    }
                }
                } else {
                    Start-Sleep -Milliseconds 50
                }
            } catch {
                # Fallback for non-interactive environments
                Start-Sleep -Milliseconds 50
            }
        }
        return $null
    }

    [void] MoveToNextColumnAndEdit() {
        Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message 'MoveToNextColumnAndEdit'
        $columns = $this.GetEditableColumns()
        if (@($columns).Count -eq 0) { $this.CancelEdit(); return }
        $currentIndex = $columns.IndexOf($this.EditingColumn)
        if ($currentIndex -lt 0) { $currentIndex = 0 }
        $nextIndex = ($currentIndex + 1) % @($columns).Count
        $nextColumn = $columns[$nextIndex]
        $currentItem = $this.CurrentData[$this.SelectedRow]
        if ($this.PendingEdits.ContainsKey($nextColumn)) {
            $nextValue = $this.PendingEdits[$nextColumn]
                Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message ("Using staged value for '{0}'" -f $nextColumn) -Data @{ Value=$nextValue }
        } else {
            $nextValue = $this.GetItemValue($currentItem, $nextColumn)
                Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message ("Using original value for '{0}'" -f $nextColumn) -Data @{ Value=$nextValue }
        }

            Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message ("Move edit focus: '{0}' -> '{1}'" -f $this.EditingColumn, $nextColumn)

        $this.EditingColumn = $nextColumn
        $this.EditingValue = $nextValue
        $this.EditCursorPos = $nextValue.Length
        $this.InlineEditMode = $true
        $this.RefreshDisplay()

        # Continue editing the new column
            Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message 'Continue edit on new column'
        $newVal = $this.HandleInlineEdit()
        if ($newVal -ne $null) {
            # Store the edit in memory instead of applying immediately
            $this.PendingEdits[$nextColumn] = $newVal
                Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message ("Staged final value for '{0}'" -f $nextColumn) -Data @{ Value=$newVal }
        }
    }

    [void] MoveToPreviousColumnAndEdit() {
        Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message 'MoveToPreviousColumnAndEdit'
        $columns = $this.GetEditableColumns()
        if (@($columns).Count -eq 0) { $this.CancelEdit(); return }
        $currentIndex = $columns.IndexOf($this.EditingColumn)
        if ($currentIndex -lt 0) { $currentIndex = 0 }
        $prevIndex = ($currentIndex - 1)
        if ($prevIndex -lt 0) { $prevIndex = @($columns).Count - 1 }
        $prevColumn = $columns[$prevIndex]
        $currentItem = $this.CurrentData[$this.SelectedRow]
        if ($this.PendingEdits.ContainsKey($prevColumn)) {
            $prevValue = $this.PendingEdits[$prevColumn]
                Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message ("Using staged value for '{0}'" -f $prevColumn) -Data @{ Value=$prevValue }
        } else {
            $prevValue = $this.GetItemValue($currentItem, $prevColumn)
                Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message ("Using original value for '{0}'" -f $prevColumn) -Data @{ Value=$prevValue }
        }

            Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message ("Move edit focus: '{0}' -> '{1}'" -f $this.EditingColumn, $prevColumn)

        $this.EditingColumn = $prevColumn
        $this.EditingValue = $prevValue
        $this.EditCursorPos = $prevValue.Length
        $this.InlineEditMode = $true
        $this.RefreshDisplay()

        # Continue editing the new column
            Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message 'Continue edit on previous column'
        $newVal = $this.HandleInlineEdit()
        if ($newVal -ne $null) {
            # Store the edit in memory instead of applying immediately
            $this.PendingEdits[$prevColumn] = $newVal
                Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message ("Staged final value for '{0}'" -f $prevColumn) -Data @{ Value=$newVal }
        }
    }

    [string[]] GetEditableColumns() {
        $cols = @()
        foreach ($c in $this.ColumnConfig.Keys) {
            if ($this.IsColumnEditable($c)) { $cols += $c }
        }
        return $cols
    }

    [bool] IsColumnEditable([string]$ColumnName) {
        if (-not $this.ColumnConfig.Keys -contains $ColumnName) { return $false }
        $cfg = $this.ColumnConfig[$ColumnName]
        $sch = $this.GetFieldSchema($ColumnName)
        $editable = $true
        if ($cfg.PSObject.Properties['Editable']) { $editable = [bool]$cfg.Editable }
        elseif ($sch -and $sch.ContainsKey('Editable')) { $editable = [bool]$sch.Editable }
        else { $editable = $true }

        $sensitive = $false
        if ($cfg.PSObject.Properties['Sensitive']) { $sensitive = [bool]$cfg.Sensitive }
        elseif ($sch -and $sch.ContainsKey('Sensitive')) { $sensitive = [bool]$sch.Sensitive }
        if ($sensitive -and (-not $this.AllowSensitiveEdits)) { return $false }
        return $editable
    }

    [void] ExitInteractive() {
        $this.Interactive = $false
        Write-Host ([PmcVT]::Show())  # Show cursor
    }

    # Display refresh method (Praxis frame-based rendering only)
    [void] RefreshDisplay() {
        if (-not $this.Interactive) { return }

        Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message 'RefreshDisplay (Praxis frame)' -Data @{ Row=$this.SelectedRow }

        # Build complete frame content using Praxis approach (single owner painter)
        $title = if ([string]::IsNullOrWhiteSpace($this.TitleText)) { 'PMC Interactive Data Grid' } else { $this.TitleText }
        $frameContent = [PraxisGridFrameBuilder]::BuildGridFrame(
            $this.CurrentData,
            $this.ColumnConfig,
            $title,
            $this.SelectedRow,
            $this.ThemeConfig,
            $this
        )

        # Single atomic write with internal double-buffering
        $this.FrameRenderer.RenderFrame($frameContent)
    }

    [string[]] RenderGridWithinBounds([object[]]$Data, [object]$ContentBounds) {
        Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message 'RenderGridWithinBounds' -Data @{
            DataCount = @($Data).Count
            BoundsWidth = $ContentBounds.Width
            BoundsHeight = $ContentBounds.Height
        }

        # Use content bounds for width/height when computing column layout
        $oldWidth = $this.TerminalWidth
        $oldHeight = $this.WindowHeight
        try {
            $this.TerminalWidth = [int]$ContentBounds.Width
            $this.WindowHeight = [int]$ContentBounds.Height
        } catch {}

        # Build lines with adjusted bounds
        $this.CurrentData = $Data
        $allLines = $this.BuildInteractiveLines()

        # Restore previous metrics
        $this.TerminalWidth = $oldWidth
        $this.WindowHeight = $oldHeight

        # Truncate to fit within content bounds
        $maxLines = $ContentBounds.Height - 1  # Reserve space for status
        $gridLines = @()

        for ($i = 0; $i -lt [Math]::Min($allLines.Count, $maxLines); $i++) {
            $line = $allLines[$i]
            # Truncate line to fit width
            if ($line.Length -gt $ContentBounds.Width) {
                $line = $line.Substring(0, $ContentBounds.Width - 3) + "..."
            }
            $gridLines += $line
        }

        return $gridLines
    }

    [void] ShowStatusLine() {
        $statusRow = [PmcTerminalService]::GetHeight() - 1
        $mode = if ($this.NavigationMode -eq "Cell") { "CELL" } else { "ROW" }
        $shownStart = [Math]::Min(@($this.CurrentData).Count, $this.ScrollOffset + 1)
        $visible = [Math]::Max(1, [PmcTerminalService]::GetHeight() - ($this.HeaderLines + 1))
        $shownEnd = [Math]::Min(@($this.CurrentData).Count, $this.ScrollOffset + $visible)
        $position = "[$($this.SelectedRow + 1)/$(@($this.CurrentData).Count) | $shownStart-$shownEnd]"
        $selection = if ($this.MultiSelectMode -and @($this.SelectedRows).Count -gt 1) { " [$(@($this.SelectedRows).Count) selected]" } else { "" }
        $filter = if ($this.FilterQuery) { " | Filter: '$($this.FilterQuery)'" } else { '' }
        $sort = if ($this.SortDirection -ne 'None' -and $this.SortColumn) { " | Sort: $($this.SortColumn) $($this.SortDirection.ToLower())" } else { '' }
        $status = "$mode $position$selection$filter$sort | Arrow keys: Navigate | Enter: Edit | Tab: Switch mode | F3: Sort | F6/F7: Save/Load view | Q: Exit"

        Write-Host ([PmcVT]::MoveTo(0, $statusRow) + [PmcVT]::ClearLine())
        Write-PmcStyled -Style 'Muted' -Text $status -NoNewline
    }

    [hashtable] GetColumnWidths([object[]]$Data) {
        $widths = @{}
        $totalFixed = 0
        $flexColumns = @()

        Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message 'GetColumnWidths' -Data @{ Width=$this.TerminalWidth; Count=$this.ColumnConfig.Keys.Count }

        # Smart default widths for common columns
        $smartDefaults = @{
            "due" = 10          # yyyy-MM-dd = 10 chars
            "priority" = 3      # P1/P2/P3 = 3 chars
            "P" = 3
            "#" = 4             # Task numbers
            "id" = 4
        }

        # Calculate fixed widths and identify flex columns (respect schema MinWidth)
        foreach ($col in $this.ColumnConfig.Keys) {
            $minW = 0
            $sch = $this.GetFieldSchema($col)
            if ($sch -and $sch.ContainsKey('MinWidth')) { try { $minW = [int]$sch.MinWidth } catch { $minW = 0 } }
            if ($smartDefaults.ContainsKey($col)) {
                # Smart defaults ALWAYS take priority for known column types
                $widths[$col] = [Math]::Max($minW, $smartDefaults[$col])
                $totalFixed += $widths[$col]
            } elseif ($this.ColumnConfig[$col].Width) {
                # Explicit width for custom columns only
                $widths[$col] = [Math]::Max($minW, [int]$this.ColumnConfig[$col].Width)
                $totalFixed += $widths[$col]
            } else {
                # This is a flex column (will get remaining space)
                $flexColumns += $col
            }
        }

        # Calculate available space for flex columns
        $padding = (@($this.ColumnConfig.Keys).Count - 1) * 2  # 2 spaces between columns
        $available = $this.TerminalWidth - $totalFixed - $padding - 4  # 4 for margins

        if (@($flexColumns).Count -gt 0) {
            $flexBase = [Math]::Max(8, [Math]::Floor($available / @($flexColumns).Count))
            foreach ($col in $flexColumns) {
                $minW = 0
                $sch2 = $this.GetFieldSchema($col)
                if ($sch2 -and $sch2.ContainsKey('MinWidth')) { try { $minW = [int]$sch2.MinWidth } catch { $minW = 0 } }
                $widths[$col] = [Math]::Max($minW, $flexBase)
            }
        }

        Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message 'GetColumnWidths result' -Data $widths
        return $widths
    }

    [string] FormatRow([object]$Item, [hashtable]$Widths, [bool]$IsHeader = $false, [int]$RowIndex = 0, [bool]$IsSelected = $false) {
        $parts = @()

        foreach ($col in $this.ColumnConfig.Keys) {
            $width = $Widths[$col]
            $formatted = ""
            $colConfig = $this.ColumnConfig[$col]

            if ($IsHeader) {
                $value = if ($colConfig.PSObject.Properties['Header']) { $colConfig.Header } else { $col }
            } else {
                $value = $this.GetItemValue($Item, $col)
            }

            # Apply truncation if needed
            if ($colConfig.PSObject.Properties['Truncate'] -and $colConfig.Truncate -and $value.Length -gt $width) {
                $value = $value.Substring(0, $width - 3) + "..."
            } elseif ($value.Length -gt $width) {
                $value = $value.Substring(0, $width)
            }

            # Apply alignment
            $alignment = if ($colConfig.PSObject.Properties['Alignment'] -and $colConfig.Alignment) { $colConfig.Alignment } else { "Left" }

            switch ($alignment) {
                "Right" { $formatted = $value.PadLeft($width) }
                "Center" {
                    $padding = $width - $value.Length
                    $leftPad = [Math]::Floor($padding / 2)
                    $rightPad = $padding - $leftPad
                    $formatted = " " * $leftPad + $value + " " * $rightPad
                }
                default { $formatted = $value.PadRight($width) }  # Left
            }

            # Apply theming to the formatted cell content
            $cellTheme = $this.GetCellTheme($Item, $col, $RowIndex, $IsHeader)

            # Apply selection highlighting
            if ($IsSelected -and -not $IsHeader) {
                $cellTheme = $this.MergeStyles($cellTheme, @{ Bg = "#0078d4"; Fg = "White" })
            }

            # Emphasize currently editing cell
            if ($this.InEditMode -and -not $IsHeader -and $RowIndex -eq $this.SelectedRow) {
                $cols = @($this.ColumnConfig.Keys)
                if ($this.NavigationMode -eq 'Cell' -and $this.SelectedColumn -lt @($cols).Count) {
                    if ($col -eq $cols[$this.SelectedColumn]) { $cellTheme = $this.MergeStyles($cellTheme, @{ Bold = $true }) }
                }
            }

            $themedText = $this.ApplyTheme($formatted, $cellTheme)
            $parts += $themedText
        }

        # Add selection indicator for row mode
        $indicator = if ($IsSelected -and -not $IsHeader) { "►" } else { " " }
        return "$indicator " + ($parts -join "  ")
    }

    [string] GetItemValue([object]$Item, [string]$ColumnName) {
        try {
            Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message ("GetItemValue: '{0}'" -f $ColumnName)
            switch ($ColumnName) {
                "id" {
                    $val = (Pmc-GetProp $Item 'id' '') -as [string]
                    Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message 'GetItemValue: id' -Data @{ Value=$val }
                    return $val
                }
                "text" {
                    $val = (Pmc-GetProp $Item 'text' '') -as [string]
                    Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message 'GetItemValue: text' -Data @{ Value=$val }
                    return $val
                }
                "Task" { return (Pmc-GetProp $Item 'text' '') -as [string] }  # Map Task to text
                "project" {
                    $projectId = (Pmc-GetProp $Item 'project' 'inbox') -as [string]
                    # Resolve project name if lookup is available
                    if ($this.ProjectLookup -and $this.ProjectLookup.PSObject.Properties[$projectId]) {
                        return $this.ProjectLookup[$projectId]
                    }
                    return $projectId
                }
                "due" {
                    $dueVal = (Pmc-GetProp $Item 'due' $null)
                    if ($dueVal) {
                        try {
                            $date = [datetime]$dueVal
                            return $date.ToString('MM/dd')
                        } catch {
                            return [string]$dueVal
                        }
                    }
                    return ""
                }
                "priority" {
                    $p = (Pmc-GetProp $Item 'priority' 0)
                    if ($p -and $p -le 3) {
                        return "P$($p)"
                    }
                    return ""
                }
                "status" {
                    if ($Item.status) {
                        return $Item.status
                    } else {
                        return "pending"
                    }
                }
                default {
                    # Dynamic property access
                    if ($Item.PSObject.Properties[$ColumnName]) {
                        return $Item.$ColumnName.ToString()
                    }
                    return ""
                }
            }
            return ""
        } catch {
            return ""
        }
    }

    [object[]] RenderGrid([object[]]$Data) {
        return $this.BuildInteractiveLines()
    }

    [object[]] BuildInteractiveLines() {
        $lines = @()
        if (-not $this.CurrentData -or @($this.CurrentData).Count -eq 0) {
            $lines += $this.StyleText('Muted', '  No data to display')
            return $lines
        }
        # Recalculate terminal metrics and adjust layout
        try {
            $this.TerminalWidth = $this.GetTerminalWidth()
            $this.WindowHeight = $this.GetTerminalHeight()
        } catch {}
        $widths = $this.GetColumnWidths($this.CurrentData)
        if ($this.ShowInternalHeader) {
            $lines += $this.StyleText('Title', $this.TitleText)
            $lines += $this.StyleText('Border', ("═" * 50))
        }
        $headerLine = $this.FormatRow($null, $widths, $true, -1, $false)
        if ($this.SortDirection -ne 'None' -and $this.SortColumn) {
            $arrow = if ($this.SortDirection -eq 'Asc') { '↑' } else { '↓' }
            $headerLine = $headerLine + "  (sorted by $($this.SortColumn) $arrow)"
        }
        $lines += $headerLine
        $separatorParts = @(); foreach ($col in $this.ColumnConfig.Keys) { $separatorParts += "─" * $widths[$col] }
        $separatorLine = "  " + ($separatorParts -join "  ")
        $lines += $this.StyleText('Border', $separatorLine)
        # Determine visible rows based on window height
        $available = [Math]::Max(1, $this.WindowHeight - ($this.HeaderLines + 1))
        $this.EnsureInView()
        $start = $this.ScrollOffset
        $endExclusive = [Math]::Min(@($this.CurrentData).Count, $start + $available)
        for ($i = $start; $i -lt $endExclusive; $i++) {
            $item = $this.CurrentData[$i]
            $isSelected = ($i -eq $this.SelectedRow) -or ($this.MultiSelectMode -and $this.SelectedRows -contains $i)
            $lines += $this.FormatRow($item, $widths, $false, $i, $isSelected)
        }
        # Indicate more content above/below when scrolled
        if ($this.ScrollOffset -gt 0) { $lines[$this.HeaderLines] = ("↑ " + ($lines[$this.HeaderLines].Substring(2))) }
        if ($endExclusive -lt @($this.CurrentData).Count) { $lines[@($lines).Count-1] = ($lines[@($lines).Count-1] + ' …') }
        return $lines
    }

    [void] EnsureInView() {
        $this.WindowHeight = $this.GetTerminalHeight()
        $available = [Math]::Max(1, $this.WindowHeight - ($this.HeaderLines + 1))
        if ($this.SelectedRow -lt $this.ScrollOffset) { $this.ScrollOffset = $this.SelectedRow }
        elseif ($this.SelectedRow -ge ($this.ScrollOffset + $available)) { $this.ScrollOffset = $this.SelectedRow - $available + 1 }
        if ($this.ScrollOffset -lt 0) { $this.ScrollOffset = 0 }
    }

    [string] StyleText([string]$StyleToken, [string]$Text) {
        $sty = Get-PmcStyle $StyleToken
        $styledText = $this.ConvertPmcStyleToAnsi($Text, $sty, @{})

        # Apply screen bounds enforcement
        return $this.EnforceScreenBounds($styledText, 0, 0)
    }

    # Main interactive method
    [void] StartInteractive([object[]]$Data) {
        Write-PmcDebug -Level 1 -Category 'Grid' -Message "StartInteractive called" -Data @{ DataCount = @($Data).Count }
        $this.Interactive = $true
        $this.AllData = $Data
        $this.ApplyFilter()
        $this.SelectedRow = 0
        $this.SelectedColumn = 0
        $this.MultiSelectMode = $false
        $this.SelectedRows = @()
        $this.HasInitialRender = $false
        $this.LastLines = @()
        $this.LastRefreshAt = Get-Date

        # Hide cursor for cleaner display
        Write-Host ([PmcVT]::Hide())
        Write-PmcDebug -Level 1 -Category 'Grid' -Message "Starting interactive loop"

        try {
            # Initial display
            $this.RefreshDisplay()

            # Main input loop
            while ($this.Interactive) {
                try {
                    if ([Console]::KeyAvailable) {
                        $key = [Console]::ReadKey($true)
                        Write-PmcDebug -Level 2 -Category 'Grid' -Message "Key pressed" -Data @{ Key = $key.Key; KeyChar = $key.KeyChar }
                        $this.HandleKeyPress($key)
                    } else {
                        if ($this.RefreshIntervalMs -gt 0) {
                            $now = Get-Date
                            if ((($now - $this.LastRefreshAt).TotalMilliseconds) -ge $this.RefreshIntervalMs) {
                                $this.LastRefreshAt = $now
                                $this.RefreshDisplay()
                            }
                        }
                        Start-Sleep -Milliseconds 50
                    }
                } catch {
                    # Fallback for non-interactive or redirected environments
                    Start-Sleep -Milliseconds 50
                    if ($this.RefreshIntervalMs -gt 0) {
                        $now = Get-Date
                        if ((($now - $this.LastRefreshAt).TotalMilliseconds) -ge $this.RefreshIntervalMs) {
                            $this.LastRefreshAt = $now
                            $this.RefreshData()
                        }
                    }
                    Start-Sleep -Milliseconds 50
                }
            }
        }
        finally {
            # Always restore cursor visibility
            Write-Host ([PmcVT]::Show())
        }
    }

    [void] HandleKeyPress([ConsoleKeyInfo]$Key) {
        $keyName = $Key.Key.ToString()

        # Handle modifier keys
        if ($Key.Modifiers -band [ConsoleModifiers]::Shift) {
            $keyName = "Shift+$keyName"
        }
        if ($Key.Modifiers -band [ConsoleModifiers]::Control) {
            $keyName = "Ctrl+$keyName"
        }

        Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message ("Key pressed: '{0}'" -f $keyName)

        # Execute key binding if it exists
        if ($this.KeyBindings.ContainsKey($keyName)) {
            Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message ("Execute key binding: '{0}'" -f $keyName)
            try {
                & $this.KeyBindings[$keyName]
            } catch {
                Write-PmcDebug -Level 1 -Category 'DataDisplay' -Message ("Key binding error: '{0}'" -f $keyName) -Data @{ Error = $_.Exception.Message }
                Write-PmcDebug -Level 1 -Category "DataDisplay" -Message "Key binding error" -Data @{
                    Key = $keyName;
                    Error = $_.Exception.Message
                }
            }
        } else {
            Write-PmcDebug -Level 3 -Category 'DataDisplay' -Message ("No key binding for: '{0}'" -f $keyName)
            # Type-to-filter: accept printable chars; Backspace handled here when not bound
            $ch = $Key.KeyChar
            if ([int]$ch -ge 32 -and [int]$ch -le 126 -and -not ($Key.Modifiers -band [ConsoleModifiers]::Control)) {
                $this.FilterQuery += [string]$ch
                $this.ApplyFilter(); $this.RefreshDisplay(); return
            }
            if ($Key.Key -eq [ConsoleKey]::Backspace -and -not ($Key.Modifiers -band [ConsoleModifiers]::Control)) {
                if ($this.FilterQuery.Length -gt 0) { $this.FilterQuery = $this.FilterQuery.Substring(0, $this.FilterQuery.Length - 1); $this.ApplyFilter(); $this.RefreshDisplay(); return }
            }
            # Unhandled key - ignore
        }
    }

    [void] ToggleSortCurrentColumn() {
        $columns = @($this.ColumnConfig.Keys)
        $col = ''
        if ($this.NavigationMode -eq 'Cell' -and $this.SelectedColumn -lt @($columns).Count) {
            $col = $columns[$this.SelectedColumn]
        } else {
            if (@($columns).Count -gt 0) { $col = $columns[0] }
        }
        if (-not $col) { return }
        if ($this.SortColumn -ne $col) { $this.SortColumn = $col; $this.SortDirection = 'Asc' }
        else {
            switch ($this.SortDirection) {
                'Asc'  { $this.SortDirection = 'Desc' }
                'Desc' { $this.SortDirection = 'None' }
                default { $this.SortDirection = 'Asc' }
            }
        }
        $this.ApplyFilter(); $this.RefreshDisplay()
    }

    [void] PromptSaveView() {
        $row = [PmcTerminalService]::GetHeight() - 2
        Write-Host ([PmcVT]::MoveTo(0, $row) + [PmcVT]::ClearLine())
        Write-Host -NoNewline "Save view as: "
        $name = Read-Host
        if ([string]::IsNullOrWhiteSpace($name)) { return }
        $this.SavedViews[$name] = @{
            Filters = $this.Filters.Clone()
            Columns = $this.ColumnConfig.Clone()
            Theme   = $this.ThemeConfig
            Sort    = @{ Column=$this.SortColumn; Direction=$this.SortDirection }
            Query   = $this.FilterQuery
        }
        $this.PersistSavedViews()
        Write-Host ([PmcVT]::MoveTo(0, $row) + [PmcVT]::ClearLine())
        Write-PmcStyled -Style 'Success' -Text ("Saved view: {0}" -f $name)
    }

    [void] PromptLoadView() {
        if ($this.SavedViews.Keys.Count -eq 0) { return }
        $row = [PmcTerminalService]::GetHeight() - 2
        Write-Host ([PmcVT]::MoveTo(0, $row) + [PmcVT]::ClearLine())
        Write-Host -NoNewline ("Load view [{0}]: " -f ($this.SavedViews.Keys -join ', '))
        $name = Read-Host
        if (-not $this.SavedViews.ContainsKey($name)) { return }
        $v = $this.SavedViews[$name]
        $this.Filters = $v.Filters
        $this.ColumnConfig = $v.Columns
        $this.ThemeConfig = $v.Theme
        $this.SortColumn = $v.Sort.Column
        $this.SortDirection = $v.Sort.Direction
        $this.FilterQuery = $v.Query
        $this.RefreshData()
    }

    [void] ListSavedViews() {
        $row = [PmcTerminalService]::GetHeight() - 2
        Write-Host ([PmcVT]::MoveTo(0, $row) + [PmcVT]::ClearLine())
        if ($this.SavedViews.Keys.Count -eq 0) { Write-PmcStyled -Style 'Muted' -Text 'No saved views'; return }
        Write-PmcStyled -Style 'Body' -Text ("Saved views: {0}" -f ($this.SavedViews.Keys -join ', '))
    }

    [void] LoadSavedViews() {
        $cfg = Get-PmcConfig
        if ($cfg -and $cfg.ContainsKey('Display') -and $cfg.Display -and $cfg.Display.ContainsKey('GridViews')) {
            $views = $cfg.Display.GridViews
            if ($views -is [hashtable]) { $this.SavedViews = $views }
        }
    }

    [void] PersistSavedViews() {
        $cfg = Get-PmcConfig
        if (-not $cfg.ContainsKey('Display')) { $cfg['Display'] = @{} }
        $cfg.Display['GridViews'] = $this.SavedViews
        Save-PmcConfig $cfg
    }

    [void] ApplyFilter() {
        if (-not $this.AllData) { $this.CurrentData = @(); return }
        if ([string]::IsNullOrWhiteSpace($this.FilterQuery)) { $this.CurrentData = $this.AllData; return }
        $q = $this.FilterQuery.ToLowerInvariant()
        $isRegex = $false
        $pattern = $null
        if ($q.StartsWith('re:')) { $isRegex = $true; $pattern = $q.Substring(3) }
        elseif ($this.FilterQuery.StartsWith('/') -and $this.FilterQuery.EndsWith('/')) { $isRegex = $true; $pattern = $this.FilterQuery.Trim('/') }
        $filtered = @()
        foreach ($it in $this.AllData) {
            if ($it -eq $null) { continue }
            $t = ''
            if ($it.PSObject.Properties['text'] -and $it.text) { $t = [string]$it.text }
            $p = ''
            if ($it.PSObject.Properties['project'] -and $it.project) { $p = [string]$it.project }
            $d = ''
            if ($it.PSObject.Properties['due'] -and $it.due) { $d = [string]$it.due }
            $hay = ($t + ' ' + $p + ' ' + $d).ToLowerInvariant()
            if ($isRegex) {
                if ($hay -match $pattern) { $filtered += $it }
            } else {
                if ($hay.Contains($q)) { $filtered += $it }
            }
        }
        # Apply sorting to filtered results
        if ($this.SortDirection -ne 'None' -and $this.SortColumn) {
            $key = $this.SortColumn; $asc = ($this.SortDirection -eq 'Asc')
            $filtered = @($filtered | Sort-Object -Property @{Expression={ if ($_.PSObject.Properties[$key]) { $_.$key } else { $null } }; Ascending=$asc})
        }
        $this.CurrentData = $filtered
        if ($this.SelectedRow -ge @($this.CurrentData).Count) { $this.SelectedRow = [Math]::Max(0, @($this.CurrentData).Count - 1) }
    }

    [void] RenderStaticGrid([array]$Data) {
        # Simple non-interactive grid rendering for compatibility
        if (-not $Data -or @($Data).Count -eq 0) {
            Write-PmcStyled -Style 'Muted' -Text "No items to display"
            return
        }

        $this.AllData = $Data
        $this.CurrentData = $Data
        $widths = $this.GetColumnWidths($Data)

        # Display header
        $headerLine = $this.FormatRow($null, $widths, $true, -1, $false)
        Write-Host $headerLine

        # Display separator
        $sepParts = @()
        foreach ($col in $this.ColumnConfig.Keys) {
            $sepParts += "─" * $widths[$col]
        }
        Write-Host ("  " + ($sepParts -join "  "))

        # Display data rows
        for ($i = 0; $i -lt @($Data).Count; $i++) {
            $item = $Data[$i]
            if ($item -ne $null) {
                $line = $this.FormatRow($item, $widths, $false, $i, $false)
                Write-Host $line
            }
        }
    }

    [void] StartInteractiveMode([hashtable]$Config) {
        # Optional configurator compatible with plan terminology
        if ($Config -and $Config.ContainsKey('AllowEditing')) { $this.LiveEditing = [bool]$Config.AllowEditing }
        if ($Config -and $Config.ContainsKey('SaveCallback')) { $this.SaveCallback = [scriptblock]$Config.SaveCallback }
        if ($this.CurrentData -and @($this.CurrentData).Count -gt 0) { $this.StartInteractive($this.CurrentData) }
    }

    [void] MoveToColumnStart() {
        if ($this.NavigationMode -ne 'Cell') { return }
        $this.SelectedColumn = 0
        $this.RefreshDisplay()
    }

    [void] MoveToColumnEnd() {
        if ($this.NavigationMode -ne 'Cell') { return }
        $columns = @($this.ColumnConfig.Keys)
        if ($columns.Count -gt 0) { $this.SelectedColumn = $columns.Count - 1 }
        $this.RefreshDisplay()
    }
}

function Get-PmcFilteredData {
    param(
        [string[]]$Domains,
        [hashtable]$Filters
    )

    $data = Get-PmcDataAlias
    $results = @()

    foreach ($domain in $Domains) {
        switch ($domain) {
            "task" {
                $items = if ($data.tasks) { @($data.tasks) } else { @() }

                # Apply filters
                if ($Filters.PSObject.Properties['status'] -and $Filters.status) {
                    $items = @($items | Where-Object { $_.PSObject.Properties['status'] -and $_.status -eq $Filters.status })
                }

                if ($Filters.PSObject.Properties['due_range'] -and $Filters.due_range) {
                    $today = (Get-Date).Date
                    switch ($Filters.due_range) {
                        "overdue_and_today" {
                            $items = @($items | Where-Object {
                                if (-not ($_.PSObject.Properties['due'] -and $_.due -and ($_.due -is [string]) -and $_.due -match '^\d{4}-\d{2}-\d{2}$')) { return $false }
                                $d = [datetime]::ParseExact([string]$_.due, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
                                return ($d.Date -le $today)
                            })
                        }
                        "today" {
                            $items = @($items | Where-Object {
                                if (-not ($_.PSObject.Properties['due'] -and $_.due -and ($_.due -is [string]) -and $_.due -match '^\d{4}-\d{2}-\d{2}$')) { return $false }
                                $d = [datetime]::ParseExact([string]$_.due, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
                                return ($d.Date -eq $today)
                            })
                        }
                        "overdue" {
                            $items = @($items | Where-Object {
                                if (-not ($_.PSObject.Properties['due'] -and $_.due -and ($_.due -is [string]) -and $_.due -match '^\d{4}-\d{2}-\d{2}$')) { return $false }
                                $d = [datetime]::ParseExact([string]$_.due, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
                                return ($d.Date -lt $today)
                            })
                        }
                        "upcoming" {
                            $weekFromNow = $today.AddDays(7)
                            $items = @($items | Where-Object {
                                if (-not ($_.PSObject.Properties['due'] -and $_.due -and ($_.due -is [string]) -and $_.due -match '^\d{4}-\d{2}-\d{2}$')) { return $false }
                                $d = [datetime]::ParseExact([string]$_.due, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
                                return ($d.Date -gt $today -and $d.Date -le $weekFromNow)
                            })
                        }
                    }
                }

                if ($Filters.ContainsKey('project') -and $Filters.project) {
                    $items = @($items | Where-Object { $_.PSObject.Properties['project'] -and $_.project -eq $Filters.project })
                }

                if ($Filters.PSObject.Properties['blocked'] -and $Filters.blocked) {
                    $items = @($items | Where-Object { $_ -ne $null -and $_.PSObject.Properties['blocked'] -and $_.blocked })
                }

                if ($Filters.PSObject.Properties['no_due_date'] -and $Filters.no_due_date) {
                    $items = @($items | Where-Object { $_ -ne $null -and (-not $_.PSObject.Properties['due'] -or -not $_.due -or $_.due -eq '') })
                }

                $results += $items
            }
            "project" {
                $items = if ($data.projects) { @($data.projects) } else { @() }

                # Apply project filters if any
                if ($Filters.archived -eq $false) {
                    $items = @($items | Where-Object { (-not (Pmc-HasProp $_ 'isArchived')) -or (-not $_.isArchived) })
                }

                $results += $items
            }
            "timelog" {
                $items = if ($data.timelogs) { @($data.timelogs) } else { @() }
                $results += $items
            }
        }
    }

    return $results
}

function Show-PmcDataGrid {
    param(
        [string[]]$Domains = @("task"),
        [hashtable]$Columns = @{},
        [hashtable]$Filters = @{},
        [string]$Title = "",
        [hashtable]$Theme = @{},
        [switch]$Interactive,
        [string]$Sort,
        [int]$RefreshIntervalMs,
        [scriptblock]$OnSelectCallback,
        [object[]]$Data
    )

    Write-PmcDebug -Level 2 -Category "DataDisplay" -Message "Rendering data grid" -Data @{
        Domains = $Domains -join ","
        ColumnCount = $Columns.Keys.Count
        FilterCount = $Filters.Keys.Count
    }

    # Default column configuration derived from FieldSchemas for common data types
    if ($Columns.Keys.Count -eq 0 -and $Domains -contains "task") {
        $fs = Get-PmcFieldSchemasForDomain -Domain 'task'
        $Columns = @{}
        foreach ($name in @('id','text','project','due','priority')) {
            $sch = $null
            if ($fs.ContainsKey($name)) { $sch = $fs[$name] }
            $h = switch ($name) { 'id' { '#'} 'text' { 'Task' } 'project' { 'Project' } 'due' { 'Due' } 'priority' { 'pri' } default { $name } }
            $w = 35
            if ($sch -and $sch.ContainsKey('DefaultWidth')) {
                $w = [int]$sch.DefaultWidth
            } else {
                switch ($name) {
                    'id' { $w = 4 }
                    'priority' { $w = 3 }
                    'due' { $w = 10 }
                    'project' { $w = 12 }
                }
            }
            $al = switch ($name) { 'id' { 'Right' } 'priority' { 'Center' } 'due' { 'Center' } default { 'Left' } }
            $editable = $true
            if ($sch -and $sch.ContainsKey('Editable')) { $editable = [bool]$sch.Editable }
            $sensitive = $false
            if ($sch -and $sch.ContainsKey('Sensitive')) { $sensitive = [bool]$sch.Sensitive }
            $truncate = ($name -eq 'text' -or $name -eq 'project')
            $Columns[$name] = @{ Header = $h; Width = $w; Alignment = $al; Editable = $editable; Sensitive = $sensitive; Truncate = $truncate }
        }
    }
    elseif ($Columns.Keys.Count -eq 0 -and $Domains -contains "project") {
        $fs = Get-PmcFieldSchemasForDomain -Domain 'project'
        $Columns = @{}
        foreach ($name in @('name','description','task_count','completion')) {
            $sch = $null
            if ($fs.ContainsKey($name)) { $sch = $fs[$name] }
            $h = switch ($name) { 'name' { 'Project' } 'description' { 'Description' } 'task_count' { 'Tasks' } 'completion' { '%' } default { $name } }
            $w = 30
            if ($sch -and $sch.ContainsKey('DefaultWidth')) {
                $w = [int]$sch.DefaultWidth
            } else {
                switch ($name) {
                    'task_count' { $w = 6 }
                    'completion' { $w = 6 }
                    'name' { $w = 20 }
                }
            }
            $al = switch ($name) { 'task_count' { 'Right' } 'completion' { 'Right' } default { 'Left' } }
            $editable = $false
            if ($sch -and $sch.ContainsKey('Editable')) { $editable = [bool]$sch.Editable }
            $sensitive = $false
            if ($sch -and $sch.ContainsKey('Sensitive')) { $sensitive = [bool]$sch.Sensitive }
            $truncate = ($name -eq 'description')
            $Columns[$name] = @{ Header = $h; Width = $w; Alignment = $al; Editable = $editable; Sensitive = $sensitive; Truncate = $truncate }
        }
    }
    elseif ($Columns.Keys.Count -eq 0 -and $Domains -contains "timelog") {
        $fs = Get-PmcFieldSchemasForDomain -Domain 'timelog'
        $Columns = @{}
        foreach ($name in @('date','project','duration','description')) {
            $sch = $null
            if ($fs.ContainsKey($name)) { $sch = $fs[$name] }
            $h = switch ($name) { 'date' { 'Date' } 'project' { 'Project' } 'duration' { 'Duration' } 'description' { 'Description' } default { $name } }
            $w = 35
            if ($sch -and $sch.ContainsKey('DefaultWidth')) {
                $w = [int]$sch.DefaultWidth
            } else {
                switch ($name) {
                    'date' { $w = 10 }
                    'project' { $w = 15 }
                    'duration' { $w = 8 }
                }
            }
            $al = switch ($name) { 'duration' { 'Right' } 'date' { 'Center' } default { 'Left' } }
            $editable = $false
            if ($sch -and $sch.ContainsKey('Editable')) { $editable = [bool]$sch.Editable }
            $sensitive = $false
            if ($sch -and $sch.ContainsKey('Sensitive')) { $sensitive = [bool]$sch.Sensitive }
            $truncate = ($name -eq 'description')
            $Columns[$name] = @{ Header = $h; Width = $w; Alignment = $al; Editable = $editable; Sensitive = $sensitive; Truncate = $truncate }
        }
    }

    # Resolve data source (explicit data wins)
    if ($PSBoundParameters.ContainsKey('Data')) {
        $data = $Data
    } else {
        # Get filtered data - HACK for help domain
        if ($Domains -contains "help") {
            # Use Get-PmcHelpData function for consistent help data
            $data = Get-PmcHelpData -Context $null
            Write-PmcDebug -Level 2 -Category "DataDisplay" -Message "Help data retrieved" -Data @{ Count = @($data).Count }
        } else {
            $data = Get-PmcFilteredData -Domains $Domains -Filters $Filters
        }
    }

    # Optional sorting for static mode
    if (-not $Interactive.IsPresent -and $Sort) {
        $sortText = [string]$Sort
        $col = $null; $asc = $true
        if ($sortText -match '^([-+]?)([A-Za-z0-9_:-]+)$') {
            $sig = $matches[1]; $name = $matches[2]
            $col = $name
            if ($sig -eq '-') { $asc = $false }
        } elseif ($sortText -match '^([^:]+):(asc|desc)$') {
            $col = $matches[1]; $asc = ($matches[2].ToLower() -eq 'asc')
        }
        if ($col) {
            $data = @($data | Sort-Object -Property @{Expression={ if ($_.PSObject.Properties[$col]) { $_.$col } else { $null } }; Ascending=$asc})
        } else {
            throw ("Invalid Sort format: '{0}'" -f $Sort)
        }
    }

    # Display title if provided
    if ($Title) {
        Write-PmcStyled -Style 'Title' -Text "`n$Title"
        Write-PmcStyled -Style 'Border' -Text ("─" * 50)
        # Helpful hint for help-related views
        $isHelp = $false
        foreach ($d in $Domains) { if ($d -like 'help*') { $isHelp = $true; break } }
        if ($isHelp) {
            Write-PmcStyled -Style 'Muted' -Text 'Tip: / opens search • Ctrl+F filter • "phrase" matches • Enter inserts'
        }
    }

    if (-not $data -or @($data).Count -eq 0) {
        Write-PmcDebug -Level 2 -Category "DataDisplay" -Message "No data found for display" -Data @{
            DataIsNull = ($data -eq $null)
            DataCount = if ($data) { @($data).Count } else { "null" }
            Domains = $Domains -join ","
        }
        Write-PmcStyled -Style 'Muted' -Text "No items match the specified criteria"
        return
    }

    # Create and configure the grid renderer
    $renderer = [PmcGridRenderer]::new($Columns, $Domains, $Filters)
    $renderer.CurrentData = $data
    $renderer.AllData = $data

    # Apply theme configuration if provided
    if ($Theme.Count -gt 0) {
        $renderer.ThemeConfig = $renderer.InitializeTheme($Theme)
    }

    # Apply additional parameters
    if ($OnSelectCallback) { $renderer.OnSelectCallback = $OnSelectCallback }

    # Choose rendering mode
    if ($Interactive) {
        # Start interactive mode
        if ($PSBoundParameters.ContainsKey('RefreshIntervalMs')) { $renderer.RefreshIntervalMs = [int]$RefreshIntervalMs }
        $renderer.StartInteractive($data)
    } else {
        # Standard static rendering
        $gridLines = $renderer.RenderGrid($data)
        foreach ($line in $gridLines) {
            Write-Host $line
        }
    }

    Write-PmcDebug -Level 2 -Category "DataDisplay" -Message "Grid rendering completed" -Data @{
        ItemCount = @($data).Count
        Interactive = $Interactive.IsPresent
    }
}

# Compatibility wrapper: Show-PmcCustomGrid → Show-PmcDataGrid
function Show-PmcCustomGrid {
    param(
        [string]$Domain,
        [hashtable]$Columns,
        [object[]]$Data,
        [string]$Title,
        [string]$Group,
        [string]$View,
        [switch]$Interactive
    )
    try {
        if (($View -and $View.ToLower() -eq 'kanban') -and (Get-Command -Name 'Show-PmcKanban' -ErrorAction SilentlyContinue)) {
            # Delegate to Kanban renderer when requested
            Show-PmcKanban -Domain $Domain -Data $Data -Columns $Columns -Title $Title -Interactive:$Interactive
            return
        }
    } catch {}

    $domains = @($Domain)
    if (-not $Columns) { $Columns = @{} }
    if ($Title) {
        Write-PmcStyled -Style 'Title' -Text "`n$Title"
        Write-PmcStyled -Style 'Border' -Text ("─" * 50)
    }
    Show-PmcDataGrid -Domains $domains -Columns $Columns -Data $Data -Interactive:$Interactive
}

# Export functions for module manifest
Export-ModuleMember -Function Show-PmcDataGrid, Show-PmcCustomGrid


# END FILE: ./module/Pmc.Strict/src/DataDisplay.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/Debug.ps1
# SIZE: 12.21 KB
# MODIFIED: 2025-09-22 15:23:10
# ================================================================================

# Structured Debug Logging System for PMC
# Multi-level debug output with file rotation and sensitive data redaction

Set-StrictMode -Version Latest

# Debug system state - now managed by centralized state
# State initialization moved to State.ps1

function Initialize-PmcDebugSystem {
    <#
    .SYNOPSIS
    Initializes the debug system based on configuration and command line arguments

    .PARAMETER Level
    Debug level (0=off, 1=basic, 2=detailed, 3=verbose)

    .PARAMETER LogPath
    Path to debug log file (relative to PMC root or absolute)
    #>
    param(
        [int]$Level = 0,
        [string]$LogPath = 'debug.log'
    )

    # Defer config loading to avoid circular dependency during initialization
    # Configuration will be applied later via Update-PmcDebugFromConfig

    # Override with explicit parameters
    if ($Level -gt 0) { Set-PmcState -Section 'Debug' -Key 'Level' -Value $Level }
    if ($LogPath -ne 'debug.log') { Set-PmcState -Section 'Debug' -Key 'LogPath' -Value $LogPath }

    # Check environment variables for debug settings
    if ($env:PMC_DEBUG) {
        try {
            $envLevel = [int]$env:PMC_DEBUG
            if ($envLevel -ge 1 -and $envLevel -le 3) {
                Set-PmcState -Section 'Debug' -Key 'Level' -Value $envLevel
            }
        } catch {
            # Environment variable parsing failed - skip environment override
        }
    }

    # Check PowerShell debug preference
    if ($DebugPreference -ne 'SilentlyContinue') {
        $debugState = Get-PmcDebugState
        Set-PmcState -Section 'Debug' -Key 'Level' -Value ([Math]::Max($debugState.Level, 1))
    }

    $debugState = Get-PmcDebugState
    if ($debugState.Level -gt 0) {
        Ensure-PmcDebugLogPath
        Write-PmcDebug -Level 1 -Category 'SYSTEM' -Message "Debug system initialized (Level=$($debugState.Level), Session=$($debugState.SessionId))"
    }
}

function Ensure-PmcDebugLogPath {
    try {
        $logPath = Get-PmcDebugLogPath
        $dir = Split-Path $logPath -Parent
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }

        # Rotate log if it's too large
        if (Test-Path $logPath) {
            $size = (Get-Item $logPath).Length
            $debugState = Get-PmcDebugState
            if ($size -gt $debugState.MaxSize) {
                $oldPath = $logPath + '.old'
                if (Test-Path $oldPath) { Remove-Item $oldPath -Force }
                Move-Item $logPath $oldPath -Force
            }
        }
    } catch {
        # Debug log path setup failed - debug output may be unavailable
        Write-PmcDebug -Level 1 -Category 'SYSTEM' -Message "Debug log setup failed: $_"
    }
}

function Get-PmcDebugLogPath {
    $debugState = Get-PmcDebugState
    $logPath = $debugState.LogPath
    if ([System.IO.Path]::IsPathRooted($logPath)) {
        return $logPath
    }

    # Relative to PMC root directory (three levels up from src)
    $root = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
    return Join-Path $root $logPath
}

function Write-PmcDebug {
    <#
    .SYNOPSIS
    Writes a debug message with specified level and category

    .PARAMETER Level
    Debug level required for this message (1=basic, 2=detailed, 3=verbose)

    .PARAMETER Category
    Category/component name (e.g., COMMAND, COMPLETION, UI, STORAGE)

    .PARAMETER Message
    Debug message content

    .PARAMETER Data
    Optional structured data to include (hashtable/object)

    .PARAMETER Timing
    Optional timing information (milliseconds)
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateRange(1,3)]
        [int]$Level,

        [Parameter(Mandatory)]
        [string]$Category,

        [Parameter(Mandatory)]
        [string]$Message,

        [object]$Data = $null,

        [int]$Timing = -1
    )

    # Skip if debug level is insufficient
    $debugState = Get-PmcDebugState
    if ($debugState.Level -lt $Level) { return }

    try {
        $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')
        $session = $debugState.SessionId
        $levelName = @('', 'DBG1', 'DBG2', 'DBG3')[$Level]

        # Build base log entry
        $logEntry = "[$timestamp] [$session] [$levelName] [$Category] $Message"

        # Add timing if provided and enabled
        if ($Timing -ge 0 -and $debugState.IncludePerformance) {
            $logEntry += " (${Timing}ms)"
        }

        # Add structured data if provided
        if ($Data) {
            try {
                $dataJson = $Data | ConvertTo-Json -Compress -Depth 3
                $logEntry += " | Data: $dataJson"
            } catch {
                $logEntry += " | Data: [Serialization Error]"
            }
        }

        # Redact sensitive information if enabled
        if ($debugState.RedactSensitive) {
            $logEntry = Protect-PmcSensitiveData $logEntry
        }

        # Write to log file
        $logPath = Get-PmcDebugLogPath
        Add-Content -Path $logPath -Value $logEntry -Encoding UTF8

    } catch {
        # Silent failure - don't let debug logging break the application
    }
}

function Protect-PmcSensitiveData {
    param([string]$Text)

    try {
        # Redact common sensitive patterns
        $protected = $Text

        # API keys, tokens, secrets
        $protected = $protected -replace '((?i)(token|secret|password|passwd|apikey|api_key|key|pwd)\s*[:=]\s*)(\S+)', '$1****'

        # Long hex strings (potential secrets/hashes)
        $protected = $protected -replace '\b[0-9a-fA-F]{32,}\b', '****'

        # Email addresses
        $protected = $protected -replace '\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b', '****@****.***'

        # File paths that might contain usernames
        $protected = $protected -replace '([C-Z]:\\Users\\)([^\\]+)', '$1****'
        $protected = $protected -replace '(/home/)([^/]+)', '$1****'

        # Credit card numbers (basic pattern)
        $protected = $protected -replace '\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b', '****-****-****-****'

        # Social Security Numbers
        $protected = $protected -replace '\b\d{3}-\d{2}-\d{4}\b', '***-**-****'

        return $protected
    } catch {
        return $Text
    }
}

function Measure-PmcOperation {
    <#
    .SYNOPSIS
    Measures execution time of a script block and logs performance data

    .PARAMETER Name
    Operation name for logging

    .PARAMETER Category
    Debug category

    .PARAMETER ScriptBlock
    Code to execute and measure

    .PARAMETER Level
    Debug level for performance logging (default 2)
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [string]$Category = 'PERF',

        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,

        [int]$Level = 2
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        $result = & $ScriptBlock
        $stopwatch.Stop()

        Write-PmcDebug -Level $Level -Category $Category -Message "$Name completed" -Timing $stopwatch.ElapsedMilliseconds

        return $result
    } catch {
        $stopwatch.Stop()
        Write-PmcDebug -Level 1 -Category $Category -Message "$Name failed: $_" -Timing $stopwatch.ElapsedMilliseconds
        throw
    }
}

function Write-PmcDebugCommand {
    <#
    .SYNOPSIS
    Debug logging specifically for command execution (Level 1)
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Command,

        [string]$Status = 'EXECUTE',

        [object]$Context = $null,

        [int]$Timing = -1
    )

    Write-PmcDebug -Level 1 -Category 'COMMAND' -Message "$Status`: $Command" -Data $Context -Timing $Timing
}

function Write-PmcDebugCompletion {
    <#
    .SYNOPSIS
    Debug logging for completion system (Level 2)
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [object]$Data = $null,

        [int]$Timing = -1
    )

    Write-PmcDebug -Level 2 -Category 'COMPLETION' -Message $Message -Data $Data -Timing $Timing
}

function Write-PmcDebugUI {
    <#
    .SYNOPSIS
    Debug logging for UI rendering (Level 3)
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [object]$Data = $null,

        [int]$Timing = -1
    )

    Write-PmcDebug -Level 3 -Category 'UI' -Message $Message -Data $Data -Timing $Timing
}

function Write-PmcDebugStorage {
    <#
    .SYNOPSIS
    Debug logging for storage operations (Level 2)
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Operation,

        [string]$File = '',

        [object]$Data = $null,

        [int]$Timing = -1
    )

    $message = if ($File) { "$Operation`: $File" } else { $Operation }
    Write-PmcDebug -Level 2 -Category 'STORAGE' -Message $message -Data $Data -Timing $Timing
}

function Get-PmcDebugStatus {
    <#
    .SYNOPSIS
    Returns current debug system status and configuration
    #>

    $logPath = Get-PmcDebugLogPath
    $logSize = if (Test-Path $logPath) { (Get-Item $logPath).Length } else { 0 }

    $debugState = Get-PmcDebugState
    return [PSCustomObject]@{
        Enabled = ($debugState.Level -gt 0)
        Level = $debugState.Level
        LogPath = $logPath
        LogSize = $logSize
        MaxSize = $debugState.MaxSize
        RedactSensitive = $debugState.RedactSensitive
        IncludePerformance = $debugState.IncludePerformance
        SessionId = $debugState.SessionId
        Uptime = ((Get-Date) - $debugState.StartTime)
    }
}

function Show-PmcDebugLog {
    <#
    .SYNOPSIS
    Shows recent debug log entries

    .PARAMETER Lines
    Number of recent lines to show (default 50)

    .PARAMETER Category
    Filter by category (optional)
    #>
    param(
        [int]$Lines = 50,
        [string]$Category = ''
    )

    $logPath = Get-PmcDebugLogPath
    if (-not (Test-Path $logPath)) {
        Write-Host "No debug log found at: $logPath" -ForegroundColor Yellow
        return
    }

    try {
        $content = Get-Content $logPath -Tail $Lines

        if ($Category) {
            $content = $content | Where-Object { $_ -match "\[$Category\]" }
        }

        foreach ($line in $content) {
            # Color code by level and category
            if ($line -match '\[DBG1\]') {
                Write-Host $line -ForegroundColor Green
            } elseif ($line -match '\[DBG2\]') {
                Write-Host $line -ForegroundColor Yellow
            } elseif ($line -match '\[DBG3\]') {
                Write-Host $line -ForegroundColor Cyan
            } elseif ($line -match '\[ERROR\]') {
                Write-Host $line -ForegroundColor Red
            } else {
                Write-Host $line
            }
        }
    } catch {
        Write-Host "Error reading debug log: $_" -ForegroundColor Red
    }
}

function Update-PmcDebugFromConfig {
    <#
    .SYNOPSIS
    Updates debug settings from configuration after config provider is ready
    #>
    try {
        $cfg = Get-PmcConfig
        if ($cfg.Debug) {
            if ($cfg.Debug.Level -ne $null) { Set-PmcState -Section 'Debug' -Key 'Level' -Value ([int]$cfg.Debug.Level) }
            if ($cfg.Debug.LogPath) { Set-PmcState -Section 'Debug' -Key 'LogPath' -Value ([string]$cfg.Debug.LogPath) }
            if ($cfg.Debug.MaxSize) {
                try {
                    $maxSize = [int64]($cfg.Debug.MaxSize -replace '[^\d]','') * 1MB
                    Set-PmcState -Section 'Debug' -Key 'MaxSize' -Value $maxSize
                } catch {
                    # Configuration parsing failed - keep default MaxSize value
                }
            }
            if ($cfg.Debug.RedactSensitive -ne $null) { Set-PmcState -Section 'Debug' -Key 'RedactSensitive' -Value ([bool]$cfg.Debug.RedactSensitive) }
            if ($cfg.Debug.IncludePerformance -ne $null) { Set-PmcState -Section 'Debug' -Key 'IncludePerformance' -Value ([bool]$cfg.Debug.IncludePerformance) }
        }
    } catch {
        # Configuration loading failed - debug system will use defaults
    }
}

# Note: Debug system is initialized by the root orchestrator after config providers are set

#Export-ModuleMember -Function Initialize-PmcDebugSystem, Ensure-PmcDebugLogPath, Get-PmcDebugLogPath, Write-PmcDebug, Protect-PmcSensitiveData, Measure-PmcOperation, Write-PmcDebugCommand, Write-PmcDebugCompletion, Write-PmcDebugUI, Write-PmcDebugStorage, Get-PmcDebugStatus, Show-PmcDebugLog, Update-PmcDebugFromConfig


# END FILE: ./module/Pmc.Strict/src/Debug.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/Dependencies.ps1
# SIZE: 10.38 KB
# MODIFIED: 2025-09-23 21:19:01
# ================================================================================

# Dependencies System Implementation
# Based on t2.ps1 dependencies functionality

function Update-PmcBlockedStatus {
    param($data = (Get-PmcDataAlias))

    Write-PmcDebug -Level 3 -Category "Dependencies" -Message "Updating blocked status for all tasks"

    # Clear all blocked status first
    foreach ($task in @($data.tasks)) {
        if ($null -eq $task) { continue }
        if (Pmc-HasProp $task 'blocked') { $task.PSObject.Properties.Remove('blocked') }
    }

    # Set blocked status for tasks with pending dependencies
    foreach ($task in @($data.tasks) | Where-Object {
        $null -ne $_ -and
        (Pmc-HasProp $_ 'depends') -and
        $_.depends -and
        $_.depends.Count -gt 0
    }) {
        $blockers = $data.tasks | Where-Object {
            Pmc-HasProp $_ 'id' -and ($_.id -in $task.depends) -and (Pmc-HasProp $_ 'status') -and $_.status -eq 'pending'
        }
        $isBlocked = ($blockers.Count -gt 0)

        if ($isBlocked) {
            if (Pmc-HasProp $task 'blocked') { $task.blocked = $true } else { Add-Member -InputObject $task -MemberType NoteProperty -Name blocked -Value $true }
        }
    }

    Write-PmcDebug -Level 3 -Category "Dependencies" -Message "Blocked status update completed"
}

function Add-PmcDependency {
    param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category "Dependencies" -Message "Starting dep add" -Data @{ FreeText = $Context.FreeText }

    $data = Get-PmcDataAlias
    $ids = $Context.FreeText

    if ($ids.Count -lt 2) {
        Write-PmcStyled -Style 'Warning' -Text "Usage: dep add <task> <depends-on>"
        return
    }

    $taskId = $null
    $dependsOnId = $null

    # Resolve task IDs
    if ($ids[0] -match '^\d+$') { $taskId = [int]$ids[0] }
    if ($ids[1] -match '^\d+$') { $dependsOnId = [int]$ids[1] }

    if (-not $taskId -or -not $dependsOnId) {
        Write-PmcStyled -Style 'Error' -Text "Invalid task IDs"
        return
    }

    $task = $data.tasks | Where-Object { $_.id -eq $taskId } | Select-Object -First 1
    $dependsOnTask = $data.tasks | Where-Object { $_.id -eq $dependsOnId } | Select-Object -First 1

    if (-not $task) {
        Write-PmcStyled -Style 'Error' -Text "Task #$taskId not found"
        return
    }

    if (-not $dependsOnTask) {
        Write-PmcStyled -Style 'Error' -Text "Task #$dependsOnId not found"
        return
    }

    # Initialize depends array if needed
    if (-not (Pmc-HasProp $task 'depends')) { $task | Add-Member -NotePropertyName depends -NotePropertyValue @() -Force }

    # Check if dependency already exists
    if ($task.depends -contains $dependsOnId) {
        Write-PmcStyled -Style 'Warning' -Text "Dependency already exists"
        return
    }

    # Add dependency
    $task.depends = @($task.depends + $dependsOnId)

    # Update blocked status for all tasks
    Update-PmcBlockedStatus -data $data

    Save-StrictData $data 'dep add'
    Write-PmcStyled -Style 'Success' -Text "Added dependency: Task #$taskId depends on Task #$dependsOnId"

    Write-PmcDebug -Level 2 -Category "Dependencies" -Message "Dependency added successfully" -Data @{ TaskId = $taskId; DependsOn = $dependsOnId }
}

function Remove-PmcDependency {
    param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category "Dependencies" -Message "Starting dep remove" -Data @{ FreeText = $Context.FreeText }

    $data = Get-PmcDataAlias
    $ids = $Context.FreeText

    if ($ids.Count -lt 2) {
        Write-PmcStyled -Style 'Warning' -Text "Usage: dep remove <task> <depends-on>"
        return
    }

    $taskId = $null
    $dependsOnId = $null

    # Resolve task IDs
    if ($ids[0] -match '^\d+$') { $taskId = [int]$ids[0] }
    if ($ids[1] -match '^\d+$') { $dependsOnId = [int]$ids[1] }

    if (-not $taskId -or -not $dependsOnId) {
        Write-PmcStyled -Style 'Error' -Text "Invalid task IDs"
        return
    }

    $task = $data.tasks | Where-Object { $_.id -eq $taskId } | Select-Object -First 1

    if (-not $task -or -not (Pmc-HasProp $task 'depends') -or -not $task.depends) {
        Write-PmcStyled -Style 'Warning' -Text "No such dependency found"
        return
    }

    # Remove dependency
    $task.depends = @($task.depends | Where-Object { $_ -ne $dependsOnId })

    # Clean up empty depends array
    if ($task.depends.Count -eq 0) { try { $task.PSObject.Properties.Remove('depends') } catch {} }

    # Update blocked status for all tasks
    Update-PmcBlockedStatus -data $data

    Save-StrictData $data 'dep remove'
    Write-Host "Removed dependency: Task #$taskId no longer depends on Task #$dependsOnId" -ForegroundColor Green

    Write-PmcDebug -Level 2 -Category "Dependencies" -Message "Dependency removed successfully" -Data @{ TaskId = $taskId; DependsOn = $dependsOnId }
}

function Show-PmcDependencies {
    param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category "Dependencies" -Message "Starting dep show" -Data @{ FreeText = $Context.FreeText }

    $data = Get-PmcDataAlias
    $text = ($Context.FreeText -join ' ').Trim()

    if (-not $text) {
        Write-Host "Usage: dep show <task>" -ForegroundColor Yellow
        return
    }

    $taskId = $null
    if ($text -match '^\d+$') { $taskId = [int]$text }

    if (-not $taskId) {
        Write-Host "Invalid task ID" -ForegroundColor Red
        return
    }

    $task = $data.tasks | Where-Object { $_.id -eq $taskId } | Select-Object -First 1

    if (-not $task) {
        Write-PmcStyled -Style 'Error' -Text "Task #$taskId not found"
        return
    }

    Write-Host "`nDEPENDENCIES for Task #$taskId" -ForegroundColor Cyan
    Write-Host ("Task: {0}" -f $task.text) -ForegroundColor White
    Write-PmcStyled -Style 'Border' -Text "─────────────────────────────────"

    $depends = if ((Pmc-HasProp $task 'depends') -and $task.depends) { $task.depends } else { @() }

    if ($depends.Count -eq 0) {
        Write-Host "  No dependencies" -ForegroundColor Gray
        return
    }

    $rows = @()
    foreach ($depId in $depends) {
        $depTask = $data.tasks | Where-Object { $_.id -eq $depId } | Select-Object -First 1
        $status = if ($depTask) { $depTask.status } else { 'missing' }
        $text = if ($depTask) { $depTask.text } else { '(missing task)' }
        $rows += @{ id = "#$depId"; status = $status; text = $text }
    }

    # Convert to universal display format
    $columns = @{
        "id" = @{ Header = "ID"; Width = 6; Alignment = "Left"; Editable = $false }
        "status" = @{ Header = "Status"; Width = 10; Alignment = "Center"; Editable = $false }
        "text" = @{ Header = "Task"; Width = 50; Alignment = "Left"; Editable = $false }
    }

    # Convert rows to PSCustomObject format
    $dataObjects = @()
    foreach ($row in $rows) {
        $obj = New-Object PSCustomObject
        foreach ($key in $row.Keys) {
            $obj | Add-Member -NotePropertyName $key -NotePropertyValue $row[$key]
        }
        $dataObjects += $obj
    }

    # Use template display
    $depTemplate = [PmcTemplate]::new('dependencies', @{
        type = 'grid'
        header = 'Task ID   Title                          Type        Status'
        row = '{id,-9} {title,-30} {type,-10} {status}'
    })
    Write-PmcStyled -Style 'Header' -Text "Dependencies for Task #$taskId"
    Render-GridTemplate -Data $dataObjects -Template $depTemplate

    # Show if this task is blocked
    if ($task.blocked) {
        Write-Host "`n⚠️  This task is BLOCKED by pending dependencies" -ForegroundColor Red
    } else {
        Write-Host "`n✅ This task is ready to work on" -ForegroundColor Green
    }

    Write-PmcDebug -Level 2 -Category "Dependencies" -Message "Dependencies shown successfully" -Data @{ TaskId = $taskId; DependencyCount = $depends.Count }
}

function Show-PmcDependencyGraph {
    param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category "Dependencies" -Message "Starting dep graph"

    $data = Get-PmcDataAlias
    $rows = @()

    foreach ($task in $data.tasks) {
        if ((Pmc-HasProp $task 'depends') -and @($task.depends).Count -gt 0) {
            $dependsText = ($task.depends -join ', ')
            $status = if ($task.blocked) { "🔒 BLOCKED" } else { "✅ Ready" }
            $rows += @{
                task = "#$($task.id)"
                depends = $dependsText
                status = $status
                text = $task.text
            }
        }
    }

    if (@($rows).Count -eq 0) {
        Write-Host "`nDEPENDENCY GRAPH" -ForegroundColor Cyan
        Write-Host "No task dependencies found" -ForegroundColor Gray
        return
    }

    # Convert to universal display format
    $columns = @{
        "task" = @{ Header = "Task"; Width = 8; Alignment = "Left"; Editable = $false }
        "depends" = @{ Header = "Depends On"; Width = 15; Alignment = "Left"; Editable = $false }
        "status" = @{ Header = "Status"; Width = 12; Alignment = "Center"; Editable = $false }
        "text" = @{ Header = "Description"; Width = 40; Alignment = "Left"; Editable = $false }
    }

    # Convert rows to PSCustomObject format
    $dataObjects = @()
    foreach ($row in $rows) {
        $obj = New-Object PSCustomObject
        foreach ($key in $row.Keys) {
            $obj | Add-Member -NotePropertyName $key -NotePropertyValue $row[$key]
        }
        $dataObjects += $obj
    }

    # Use template display
    $depTemplate = [PmcTemplate]::new('dep-graph', @{
        type = 'grid'
        header = 'Task ID   Title                          Type        Status'
        row = '{id,-9} {title,-30} {type,-10} {status}'
    })
    Write-PmcStyled -Style 'Header' -Text 'DEPENDENCY GRAPH'
    Render-GridTemplate -Data $dataObjects -Template $depTemplate

    # Summary statistics
    $blockedCount = @($data.tasks | Where-Object { $_.blocked }).Count
    $dependentCount = @($data.tasks | Where-Object { (Pmc-HasProp $_ 'depends') -and $_.depends }).Count

    Write-Host "`nSummary:" -ForegroundColor Cyan
    Write-Host "  Tasks with dependencies: $dependentCount" -ForegroundColor White
    Write-Host "  Currently blocked tasks: $blockedCount" -ForegroundColor $(if ($blockedCount -gt 0) { 'Red' } else { 'Green' })

    Write-PmcDebug -Level 2 -Category "Dependencies" -Message "Dependency graph shown successfully" -Data @{ DependentTasks = $dependentCount; BlockedTasks = $blockedCount }
}

Export-ModuleMember -Function Update-PmcBlockedStatus, Add-PmcDependency, Remove-PmcDependency, Show-PmcDependencies, Show-PmcDependencyGraph


# END FILE: ./module/Pmc.Strict/src/Dependencies.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/Excel.ps1
# SIZE: 12.03 KB
# MODIFIED: 2025-09-22 15:23:10
# ================================================================================

# ExcelT2020.ps1 - Excel T2020 integration for PMC
# Restored from working ExcelT2020.psm1 functionality

# =============================
# Editable Configuration Section
# =============================

# Global configuration variables (user-editable)
$Global:ExcelT2020_SourceFolder = Join-Path $PSScriptRoot 'excel_input'
$Global:ExcelT2020_DestinationPath = Join-Path $PSScriptRoot 'excel_output.xlsm'
$Global:ExcelT2020_DestSheetName = 'Output'
$Global:ExcelT2020_SourceSheetName = 'SVI-CAS'

# Field mappings: copy from SourceSheet:SourceCell to DestSheet:DestCell
$Global:ExcelT2020_Mappings = @(
    @{ Field='RequestDate';    SourceCell='W23'; DestCell='B2'  }
    @{ Field='AuditType';      SourceCell='W78'; DestCell='B3'  }
    @{ Field='AuditorName';    SourceCell='W10'; DestCell='B4'  }
    @{ Field='TPName';         SourceCell='W3';  DestCell='B5'  }
    @{ Field='TPEmailAddress'; SourceCell='X3';  DestCell='B6'  }
    @{ Field='TPPhoneNumber';  SourceCell='Y3';  DestCell='B7'  }
    @{ Field='TaxID';          SourceCell='W13'; DestCell='B8'  }
    @{ Field='CASNumber';      SourceCell='G17'; DestCell='B9'  }
)

# Logging and summary storage
$Global:ExcelT2020_LogPath = Join-Path $PSScriptRoot 'excel_t2020.log'
$Global:ExcelT2020_SummaryPath = Join-Path $PSScriptRoot 'excel_t2020_summary.json'

# =============================
# Excel COM Management
# =============================

$script:ExcelApp = $null

function New-ExcelApp {
    if ($script:ExcelApp -ne $null) { return $script:ExcelApp }
    try {
        $app = New-Object -ComObject Excel.Application
        $app.Visible = $false
        $app.DisplayAlerts = $false
        $script:ExcelApp = $app
        return $script:ExcelApp
    } catch {
        throw "Excel COM is not available. Ensure Excel is installed. Error: $_"
    }
}

function Close-ExcelApp {
    if ($script:ExcelApp -ne $null) {
        try { $script:ExcelApp.Quit() } catch {}
        try { [void][Runtime.InteropServices.Marshal]::ReleaseComObject($script:ExcelApp) } catch {}
        $script:ExcelApp = $null
    }
}

function Open-Workbook {
    param(
        [Parameter(Mandatory)] [string]$Path,
        [switch]$ReadOnly
    )
    $app = New-ExcelApp
    if (-not (Test-Path $Path)) { throw "Workbook not found: $Path" }
    try { return $app.Workbooks.Open($Path, $false, [bool]$ReadOnly) } catch { throw "Failed to open workbook '$Path': $_" }
}

function Save-Workbook {
    param([Parameter(Mandatory)] $Workbook)
    try { $Workbook.Save() } catch { throw "Failed to save workbook: $_" }
}

function Close-Workbook {
    param([Parameter(Mandatory)] $Workbook)
    try { $Workbook.Close($false) } catch {}
}

function Get-Worksheet {
    param(
        [Parameter(Mandatory)] $Workbook,
        [Parameter(Mandatory)] [string]$Name
    )
    try { return $Workbook.Worksheets.Item($Name) } catch { throw "Worksheet '$Name' not found in '$($Workbook.Name)'." }
}

# =============================
# Core T2020 Operations
# =============================

function Copy-CellValue {
    param(
        [Parameter(Mandatory)] $SourceSheet,
        [Parameter(Mandatory)] [string]$SourceCell,
        [Parameter(Mandatory)] $DestSheet,
        [Parameter(Mandatory)] [string]$DestCell
    )
    $srcRange = $SourceSheet.Range($SourceCell)
    $dstRange = $DestSheet.Range($DestCell)

    $val = $srcRange.Value2
    if ($null -eq $val -or $val -eq '') {
        $dstRange.Value2 = ''
    } else {
        $srcRange.Copy() | Out-Null
        $dstRange.PasteSpecial(-4163) | Out-Null  # xlPasteValues
        (New-ExcelApp).CutCopyMode = 0
    }
}

function Extract-T2020Fields {
    param(
        [Parameter(Mandatory)] [string]$SourcePath,
        [string]$SourceSheetName = $Global:ExcelT2020_SourceSheetName,
        [array] $Mappings        = $Global:ExcelT2020_Mappings
    )
    $srcWb = $null
    try {
        $srcWb = Open-Workbook -Path $SourcePath -ReadOnly
        $wsSrc = Get-Worksheet -Workbook $srcWb -Name $SourceSheetName
        $data = [ordered]@{}
        foreach ($m in $Mappings) {
            $val = $wsSrc.Range($m.SourceCell).Value2
            $data[$m.Field] = $val
        }
        return @{ Success=$true; Data=$data }
    } catch {
        return @{ Success=$false; Error="Extract failed: $_" }
    } finally {
        if ($srcWb) { Close-Workbook -Workbook $srcWb }
    }
}

function Copy-T2020ForFile {
    param(
        [Parameter(Mandatory)] [string]$SourcePath,
        [Parameter(Mandatory)] [string]$DestinationPath,
        [string]$SourceSheetName = $Global:ExcelT2020_SourceSheetName,
        [string]$DestSheetName   = $Global:ExcelT2020_DestSheetName,
        [array] $Mappings        = $Global:ExcelT2020_Mappings
    )
    $srcWb = $null; $dstWb = $null
    try {
        $srcWb = Open-Workbook -Path $SourcePath -ReadOnly
        $dstWb = Open-Workbook -Path $DestinationPath

        $wsSrc = Get-Worksheet -Workbook $srcWb -Name $SourceSheetName
        $wsDst = Get-Worksheet -Workbook $dstWb -Name $DestSheetName

        foreach ($m in $Mappings) {
            Copy-CellValue -SourceSheet $wsSrc -SourceCell $m.SourceCell -DestSheet $wsDst -DestCell $m.DestCell
        }

        Save-Workbook -Workbook $dstWb
        return @{ Success=$true; Message="Copied $($Mappings.Count) fields from '$SourcePath' to '$DestinationPath'" }
    } catch {
        return @{ Success=$false; Error="Copy failed: $_" }
    } finally {
        if ($srcWb) { Close-Workbook -Workbook $srcWb }
        if ($dstWb) { Close-Workbook -Workbook $dstWb }
    }
}

function Invoke-T2020Batch {
    param(
        [string]$SourceFolder = $Global:ExcelT2020_SourceFolder,
        [string]$DestinationPath = $Global:ExcelT2020_DestinationPath,
        [string]$SourcePattern = '*.xlsm',
        [switch]$WhatIf
    )
    if (-not (Test-Path $SourceFolder)) { throw "Source folder not found: $SourceFolder" }
    $files = Get-ChildItem -Path $SourceFolder -Filter $SourcePattern -File | Sort-Object Name
    if ($files.Count -eq 0) { return @{ Success=$true; Message='No files found'; Processed=0 } }

    $processed = 0
    $summary = @()
    foreach ($f in $files) {
        if ($WhatIf) {
            Write-Host "Would copy from '$($f.FullName)' to '$DestinationPath'" -ForegroundColor Yellow
            continue
        }
        $extract = Extract-T2020Fields -SourcePath $f.FullName
        $res = Copy-T2020ForFile -SourcePath $f.FullName -DestinationPath $DestinationPath
        $ok = ($res.Success -and $extract.Success)
        $processed += [int]$ok
        $record = [ordered]@{
            Timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            Source    = $f.FullName
            Destination = $DestinationPath
            Count     = $Global:ExcelT2020_Mappings.Count
            Success   = $ok
            Error     = if ($ok) { '' } else { ($res.Error ?? $extract.Error) }
            Fields    = if ($extract.Success) { $extract.Data } else { @{} }
        }
        $summary += $record
        try {
            "$($record.Timestamp) | $($record.Source) -> $($record.Destination) | Count=$($record.Count) | Success=$($record.Success) | $($record.Error)" | Add-Content -Path $Global:ExcelT2020_LogPath -Encoding UTF8
        } catch {}
    }
    # Persist JSON summary (append)
    try {
        $existing = @()
        if (Test-Path $Global:ExcelT2020_SummaryPath) {
            $existing = Get-Content $Global:ExcelT2020_SummaryPath -Raw | ConvertFrom-Json
        }
        $all = @()
        if ($existing) { $all += $existing }
        $all += $summary
        ($all | ConvertTo-Json -Depth 10) | Set-Content -Path $Global:ExcelT2020_SummaryPath -Encoding UTF8
    } catch {}
    return @{ Success=$true; Processed=$processed; Summary=$summary }
}

function Set-ExcelT2020Config {
    param(
        [string]$SourceFolder,
        [string]$DestinationPath,
        [string]$SourceSheetName,
        [string]$DestSheetName
    )
    if ($PSBoundParameters.ContainsKey('SourceFolder'))     { $Global:ExcelT2020_SourceFolder = $SourceFolder }
    if ($PSBoundParameters.ContainsKey('DestinationPath'))  { $Global:ExcelT2020_DestinationPath = $DestinationPath }
    if ($PSBoundParameters.ContainsKey('SourceSheetName'))  { $Global:ExcelT2020_SourceSheetName = $SourceSheetName }
    if ($PSBoundParameters.ContainsKey('DestSheetName'))    { $Global:ExcelT2020_DestSheetName = $DestSheetName }
}

# =============================
# PMC Excel Command Functions
# =============================

function Import-PmcFromExcel {
    [CmdletBinding()]
    param([PmcCommandContext]$Context)

    try {
        $result = Invoke-T2020Batch -WhatIf:$Context.Args.ContainsKey('whatif')

        if (-not $result.Success) {
            Write-PmcStyled -Style 'Error' -Text ("Excel import failed: {0}" -f $result.Error)
            return
        }

        # Simple display
        Write-PmcStyled -Style 'Success' -Text ("Excel T2020 import completed: {0} files processed" -f $result.Processed)

        # Store import history
        $data = Get-PmcData
        if (-not $data.excelImports) {
            $data | Add-Member -NotePropertyName excelImports -NotePropertyValue @() -Force
        }
        $data.excelImports += $result.Summary

        # Keep only last 50 imports
        if ($data.excelImports.Count -gt 50) {
            $data.excelImports = $data.excelImports[-50..-1]
        }

        Save-PmcData -Data $data

    } catch {
        Write-PmcStyled -Style 'Error' -Text ("Excel import error: {0}" -f $_)
    } finally {
        Close-ExcelApp
    }
}

# Wrappers to align with CommandMap function names
function Import-PmcExcelData { param([PmcCommandContext]$Context) Import-PmcFromExcel -Context $Context }
function Show-PmcExcelPreview { param([PmcCommandContext]$Context) Show-PmcExcelData -Context $Context }
function Get-PmcLatestExcelFile { param([PmcCommandContext]$Context) Get-PmcLatestExcelData -Context $Context }

function Show-PmcExcelData {
    param([PmcCommandContext]$Context)
    try {
        if (-not (Test-Path $Global:ExcelT2020_SourceFolder)) {
            Write-PmcStyled -Style 'Error' -Text "Source folder not found: $Global:ExcelT2020_SourceFolder"
            return
        }
        $files = Get-ChildItem -Path $Global:ExcelT2020_SourceFolder -Filter '*.xlsm' -File
        if ($files.Count -eq 0) {
            Write-PmcStyled -Style 'Warning' -Text "No Excel files found in: $Global:ExcelT2020_SourceFolder"
            return
        }
        $extract = Extract-T2020Fields -SourcePath $files[0].FullName
        if ($extract.Success) {
            Write-PmcStyled -Style 'Info' -Text "Excel T2020 Preview ($($files.Count) files found):"
            foreach ($field in $extract.Data.GetEnumerator()) {
                $value = if ($field.Value -and $field.Value.ToString().Length -gt 30) { $field.Value.ToString().Substring(0, 27) + "..." } else { $field.Value }
                Write-Host "  $($field.Key): $value"
            }
        } else {
            Write-PmcStyled -Style 'Error' -Text "Failed to preview: $($extract.Error)"
        }
    } catch {
        Write-PmcStyled -Style 'Error' -Text "Excel view error: $_"
    } finally {
        Close-ExcelApp
    }
}

function Get-PmcLatestExcelData {
    param([PmcCommandContext]$Context)
    try {
        $data = Get-PmcData
        $imports = @($data.excelImports)
        if ($imports.Count -eq 0) {
            Write-PmcStyled -Style 'Warning' -Text "No Excel imports found. Run 'excel import' first."
            return
        }
        $recent = $imports | Select-Object -Last 10
        Write-PmcStyled -Style 'Info' -Text "Recent Excel Imports:"
        foreach ($import in $recent) {
            $status = if ($import.Success) { '✓' } else { '✗' }
            Write-Host "  $($import.Timestamp) $($import.Source) $status"
        }
    } catch {
        Write-PmcStyled -Style 'Error' -Text "Excel latest error: $_"
    }
}

#Export-ModuleMember -Function New-ExcelApp, Close-ExcelApp, Open-Workbook, Save-Workbook, Close-Workbook, Get-Worksheet, Copy-CellValue, Extract-T2020Fields, Copy-T2020ForFile, Invoke-T2020Batch, Set-ExcelT2020Config, Import-PmcFromExcel, Import-PmcExcelData, Show-PmcExcelPreview, Get-PmcLatestExcelFile, Show-PmcExcelData, Get-PmcLatestExcelData



# END FILE: ./module/Pmc.Strict/src/Excel.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/ExcelFlowLite.ps1
# SIZE: 25.82 KB
# MODIFIED: 2025-09-20 09:34:03
# ================================================================================

# ExcelFlowLite.ps1 - Minimal interactive path picker + config hooks for Excel flow

Set-StrictMode -Version Latest

function Get-XFlowCfgVal {
    param([object]$Cfg,[string]$Key,[object]$Default=$null)
    if ($Cfg -is [hashtable]) { if ($Cfg.ContainsKey($Key)) { return $Cfg[$Key] } else { return $Default } }
    if ($Cfg -is [pscustomobject]) { if ($Cfg.PSObject.Properties[$Key]) { return $Cfg.$Key } else { return $Default } }
    return $Default
}

function Get-XFlowMapVal {
    param([object]$Map,[string]$Key,[object]$Default=$null)
    if ($Map -is [hashtable]) { if ($Map.ContainsKey($Key)) { return $Map[$Key] } else { return $Default } }
    if ($Map -is [pscustomobject]) { if ($Map.PSObject.Properties[$Key]) { return $Map.$Key } else { return $Default } }
    return $Default
}

function Get-PmcXFlowConfig {
    $data = Get-PmcData
    if (-not $data.PSObject.Properties['excelFlow']) {
        $data | Add-Member -NotePropertyName excelFlow -NotePropertyValue @{ config=@{}; runs=@() } -Force
    } else {
        if (-not ($data.excelFlow -is [hashtable])) { try { $data.excelFlow = @{} + $data.excelFlow } catch { $data.excelFlow = @{} } }
        if (-not $data.excelFlow.PSObject.Properties['config']) { $data.excelFlow['config'] = @{} }
        if (-not $data.excelFlow.PSObject.Properties['runs']) { $data.excelFlow['runs'] = @() }
    }
    return $data
}

function Set-PmcXFlowConfigValue {
    param(
        [Parameter(Mandatory)] [string]$Key,
        [Parameter(Mandatory)] [string]$Value
    )
    $data = Get-PmcXFlowConfig
    $data.excelFlow.config[$Key] = $Value
    Save-PmcData -Data $data -Action ("xflow:set:{0}" -f $Key)
}

function Invoke-PmcPathPicker {
    param(
        [string]$StartDir = '.',
        [ValidateSet('File','Directory')] [string]$Pick = 'File',
        [string[]]$Extensions = @(),
        [string]$Title = 'Select Path'
    )

    # Resolve and validate starting directory
    $current = $StartDir
    try { if (-not (Test-Path $current)) { $current = (Get-Location).Path } } catch { $current = (Get-Location).Path }

    while ($true) {
        # Gather entries
        $rows = @()

        # Parent directory entry when possible
        try {
            $root = [System.IO.Path]::GetPathRoot([System.IO.Path]::GetFullPath($current))
        } catch { $root = $current }
        if ($current -ne $root) {
            $parent = Split-Path $current -Parent
            $rows += [pscustomobject]@{
                Name = '..'
                Type = 'Dir'
                Size = ''
                Modified = ''
                Path = $parent
            }
        }

        # Directories first
        try {
            $dirs = Get-ChildItem -LiteralPath $current -Directory -ErrorAction SilentlyContinue | Sort-Object Name
            foreach ($d in $dirs) {
                $rows += [pscustomobject]@{
                    Name = $d.Name
                    Type = 'Dir'
                    Size = ''
                    Modified = $d.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
                    Path = $d.FullName
                }
            }
        } catch {}

        # Files
        try {
            $files = Get-ChildItem -LiteralPath $current -File -ErrorAction SilentlyContinue
            if ($Extensions -and @($Extensions).Count -gt 0) {
                # Normalize extensions list to regex
                $patterns = @()
                foreach ($pat in $Extensions) {
                    if ([string]::IsNullOrWhiteSpace($pat)) { continue }
                    $esc = [Regex]::Escape($pat.Trim())
                    $esc = $esc.Replace('\\*', '.*').Replace('\\?', '.')
                    $patterns += "^$esc$"
                }
                $files = $files | Where-Object { $name = $_.Name; $patterns | Where-Object { $name -match $_ } }
            }
            $files = $files | Sort-Object Name
            foreach ($f in $files) {
                $rows += [pscustomobject]@{
                    Name = $f.Name
                    Type = 'File'
                    Size = $f.Length
                    Modified = $f.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
                    Path = $f.FullName
                }
            }
        } catch {}

        # Add a cancel row to allow exit without selection
        $rows = ,([pscustomobject]@{ Name='[Cancel]'; Type='Action'; Size=''; Modified=''; Path='' }) + $rows

        # Columns configuration
        $cols = @{
            Name     = @{ Header='Name';     Width=38; Alignment='Left' }
            Type     = @{ Header='Type';     Width=6;  Alignment='Left' }
            Size     = @{ Header='Size';     Width=10; Alignment='Right' }
            Modified = @{ Header='Modified'; Width=16; Alignment='Center' }
        }

        # Render interactively using ScreenManager header + grid in navigation mode
        $displayTitle = "{0} — {1}" -f $Title, $current
        if (Get-Command Set-PmcHeader -ErrorAction SilentlyContinue) {
            Set-PmcHeader -Title $displayTitle -Status 'Nav: ENTER select  •  Q exit'
            if (Get-Command Clear-PmcContentArea -ErrorAction SilentlyContinue) { Clear-PmcContentArea }
        } else {
            Write-PmcStyled -Style 'Title' -Text ("`n$displayTitle")
            $winW = [PmcTerminalService]::GetWidth()
            Write-PmcStyled -Style 'Border' -Text ("─" * [Math]::Max(20, $winW))
        }

        $selectedIndex = 1
        try {
            $renderer = [PmcGridRenderer]::new($cols, @('file-browser'), @{})
            $renderer.EditMode = $false  # Navigation mode
            $script:_xflow_picker_selectedIndex = -1
            $renderer.OnSelectCallback = { param($item, $row) $script:_xflow_picker_selectedIndex = $row; $renderer.Interactive = $false }
            $renderer.StartInteractive($rows)
            if ($script:_xflow_picker_selectedIndex -ge 0) { $selectedIndex = [int]$script:_xflow_picker_selectedIndex }
            else { $selectedIndex = [int]$renderer.SelectedRow }
        } catch {
            $selectedIndex = 1
        }

        if ($selectedIndex -lt 0 -or $selectedIndex -ge @($rows).Count) { return '' }
        $sel = $rows[$selectedIndex]
        if ($sel.Name -eq '[Cancel]') { return '' }

        if ($sel.Type -eq 'Dir') {
            if ($Pick -eq 'Directory') { return [string]$sel.Path }
            # Drill into directory and refresh
            $current = [string]$sel.Path
            continue
        }

        if ($sel.Type -eq 'File') {
            if ($Pick -eq 'File') { return [string]$sel.Path }
            # If picking a directory but file selected, stay in loop
            continue
        }
    }
}

function Set-PmcXFlowSourcePathInteractive {
    param([PmcCommandContext]$Context)
    try {
        $data = Get-PmcXFlowConfig
        $start = (Get-Location).Path
        if ($data.excelFlow.config.ContainsKey('SourceFile')) {
            try { $start = Split-Path [string]$data.excelFlow.config['SourceFile'] -Parent } catch {}
        }
        $path = Invoke-PmcPathPicker -StartDir $start -Pick 'File' -Extensions @('*.xls','*.xlsx','*.xlsm') -Title 'Select Source Excel Workbook'
        if ([string]::IsNullOrWhiteSpace($path)) {
            Write-PmcStyled -Style 'Warning' -Text 'No source file selected.'
            return
        }
        Set-PmcXFlowConfigValue -Key 'SourceFile' -Value $path
        Write-PmcStyled -Style 'Success' -Text ("SourceFile set: {0}" -f $path)
    } catch {
        Write-PmcStyled -Style 'Error' -Text ("Source selection failed: {0}" -f $_)
    }
}

function Set-PmcXFlowDestPathInteractive {
    param([PmcCommandContext]$Context)
    try {
        $data = Get-PmcXFlowConfig
        $start = (Get-Location).Path
        if ($data.excelFlow.config.ContainsKey('DestFile')) {
            try { $start = Split-Path [string]$data.excelFlow.config['DestFile'] -Parent } catch {}
        } elseif ($data.excelFlow.config.ContainsKey('SourceFile')) {
            try { $start = Split-Path [string]$data.excelFlow.config['SourceFile'] -Parent } catch {}
        }
        $path = Invoke-PmcPathPicker -StartDir $start -Pick 'File' -Extensions @('*.xls','*.xlsx','*.xlsm') -Title 'Select Destination Excel Workbook'
        if ([string]::IsNullOrWhiteSpace($path)) {
            Write-PmcStyled -Style 'Warning' -Text 'No destination file selected.'
            return
        }
        Set-PmcXFlowConfigValue -Key 'DestFile' -Value $path
        Write-PmcStyled -Style 'Success' -Text ("DestFile set: {0}" -f $path)
    } catch {
        Write-PmcStyled -Style 'Error' -Text ("Destination selection failed: {0}" -f $_)
    }
}

function Get-PmcXFlowConfigData {
    # Returns current config without inventing field mappings
    $data = Get-PmcXFlowConfig
    return $data.excelFlow.config
}

function Save-PmcXFlowConfigData {
    param([hashtable]$Config)
    $data = Get-PmcXFlowConfig
    $data.excelFlow.config = $Config
    Save-PmcData -Data $data -Action 'xflow:save-config'
}

function New-XFlowWorkbook {
    param([string]$Path)
    try {
        $app = $null
        try { $app = New-ExcelApp } catch { $app = $null }
        if (-not $app) { $app = New-Object -ComObject Excel.Application }
        $app.Visible = $false; $app.DisplayAlerts = $false
        $wb = $app.Workbooks.Add()
        $wb.SaveAs($Path)
        return $wb
    } catch { throw "Failed to create workbook: $_" }
}

function Get-OrAddWorksheet {
    param([Parameter(Mandatory)] $Workbook,[Parameter(Mandatory)][string]$Name)
    try { return $Workbook.Worksheets.Item($Name) } catch {
        try { $ws = $Workbook.Worksheets.Add(); $ws.Name = $Name; return $ws } catch { throw "Failed to get or create sheet '$Name': $_" }
    }
}

function Export-XFlowToJson {
    param([hashtable]$Data,[string]$OutPath)
    $obj = @{ ExportTimestamp=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss'); FieldCount=$Data.Count; Data=$Data }
    $safe = Get-PmcSafePath $OutPath
    $dir = Split-Path $safe -Parent; if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $obj | ConvertTo-Json -Depth 10 | Set-Content -Path $safe -Encoding UTF8
    return $safe
}

function Export-XFlowToCsv {
    param([hashtable]$Data,[string]$OutPath)
    $headers = $Data.Keys | Sort-Object
    $vals = @(); foreach ($h in $headers) { $v = if ($Data[$h]) { $Data[$h].ToString() } else { '' }; if ($v -match ',|"|`n') { $v = '"' + $v.Replace('"','""') + '"' }; $vals += $v }
    $lines = @(); $lines += ($headers -join ','); $lines += ($vals -join ',')
    $safe = Get-PmcSafePath $OutPath
    $dir = Split-Path $safe -Parent; if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $lines | Set-Content -Path $safe -Encoding UTF8
    return $safe
}

function Show-PmcXFlowPreview {
    param([PmcCommandContext]$Context)
    $max = 10; try { if ($Context.Args.ContainsKey('max')) { $max = [int]$Context.Args['max'] } } catch {}
    $dry = $false; try { $dry = $Context.Args.ContainsKey('dry') } catch {}
    $cfg = Get-PmcXFlowConfigData
    if (-not ($cfg -is [hashtable]) -or -not $cfg.ContainsKey('FieldMappings') -or @($cfg['FieldMappings'].Keys).Count -eq 0) { Write-PmcStyled -Style 'Warning' -Text 'No FieldMappings configured. Import mappings first.'; return }

    if ($dry) {
        Write-PmcStyled -Style 'Title' -Text 'XFlow Preview (dry)'
        Write-PmcStyled -Style 'Border' -Text ("─" * 50)
        $names = $cfg['FieldMappings'].Keys | Select-Object -First $max
        foreach ($n in $names) {
            $map = $cfg['FieldMappings'][$n]
            $cell = [string](Get-XFlowMapVal $map 'Cell' '')
            $srcSheet = [string](Get-XFlowMapVal $map 'Sheet' (Get-XFlowCfgVal $cfg 'SourceSheet' ''))
            Write-Host ("  {0,-20} {1,-12} {2,-10} {3}" -f $n, $srcSheet, $cell, '(dry)')
        }
        return
    }

    $srcPath = [string](Get-XFlowCfgVal $cfg 'SourceFile' '')
    if (-not $srcPath) { Write-PmcStyled -Style 'Warning' -Text 'No SourceFile configured. Use xflow browse-source.'; return }
    if (-not (Test-Path $srcPath)) { Write-PmcStyled -Style 'Error' -Text ("Source file not found: {0}" -f $srcPath); return }

    $srcWb = $null
    try {
        $srcWb = Open-Workbook -Path $cfg.SourceFile -ReadOnly
        $sheetCache = @{}
        $names = $cfg['FieldMappings'].Keys | Select-Object -First $max
        Write-PmcStyled -Style 'Title' -Text ("XFlow Preview - {0}" -f (Split-Path $srcPath -Leaf))
        Write-PmcStyled -Style 'Border' -Text ("─" * 50)
        foreach ($n in $names) {
            $map = $cfg['FieldMappings'][$n]
            $cell = [string](Get-XFlowMapVal $map 'Cell' '')
            $srcSheet = [string](Get-XFlowMapVal $map 'Sheet' (Get-XFlowCfgVal $cfg 'SourceSheet' ''))
            if (-not $sheetCache.ContainsKey($srcSheet)) { $sheetCache[$srcSheet] = Get-Worksheet -Workbook $srcWb -Name $srcSheet }
            $wsSrc = $sheetCache[$srcSheet]
            $val = $null; try { $val = $wsSrc.Range($cell).Value2 } catch {}
            $short = if ($val) { $s=$val.ToString(); if ($s.Length -gt 50) { $s.Substring(0,47)+'...' } else { $s } } else { '' }
            Write-Host ("  {0,-20} {1,-12} {2,-10} {3}" -f $n, $srcSheet, $cell, $short)
        }
    } catch {
        Write-PmcStyled -Style 'Error' -Text ("Preview failed: {0}" -f $_)
    } finally {
        if ($srcWb) { Close-Workbook -Workbook $srcWb }
        Close-ExcelApp
    }
}

function Invoke-PmcXFlowRun {
    param([PmcCommandContext]$Context)
    $args = $Context.Args
    $whatIf = $args.ContainsKey('whatif')
    $noExcel = $args.ContainsKey('noexcel') -or $args.ContainsKey('noexcelexport')
    $dry = $args.ContainsKey('dry')
    $format = $null; if ($args.ContainsKey('format')) { $format = [string]$args['format'] }
    $valuesPath = $null; if ($args.ContainsKey('values')) { $valuesPath = [string]$args['values'] }

    $cfg = Get-PmcXFlowConfigData
    if (-not ($cfg -is [hashtable]) -or -not $cfg.ContainsKey('FieldMappings') -or @($cfg['FieldMappings'].Keys).Count -eq 0) { Write-PmcStyled -Style 'Warning' -Text 'No FieldMappings configured. Import mappings first.'; return }

    $start = Get-Date
    $srcWb = $null; $dstWb = $null
    $extracted = @{}
    $errors = @()

    try {
        if ($dry) {
            # Build synthetic extraction values
            $provided = $null
            if ($valuesPath -and (Test-Path $valuesPath)) {
                try {
                    $raw = Get-Content -Path $valuesPath -Raw | ConvertFrom-Json -AsHashtable
                    if ($raw.ContainsKey('Data')) { $provided = $raw['Data'] } else { $provided = $raw }
                } catch { $provided = $null; $errors += "Failed to parse values file: $valuesPath" }
            }
            foreach ($field in $cfg['FieldMappings'].Keys) {
                if ($provided -and ($provided -is [hashtable]) -and $provided.ContainsKey($field)) {
                    $extracted[$field] = $provided[$field]
                } else {
                    $m = $cfg['FieldMappings'][$field]
                    $srcSheet = [string](Get-XFlowMapVal $m 'Sheet' (Get-XFlowCfgVal $cfg 'SourceSheet' ''))
                    $cell = [string](Get-XFlowMapVal $m 'Cell' '')
                    $extracted[$field] = ("<{0}!{1}>" -f $srcSheet, $cell)
                }
            }
        } else {
            $srcPath = [string](Get-XFlowCfgVal $cfg 'SourceFile' '')
            if (-not $srcPath) { Write-PmcStyled -Style 'Warning' -Text 'No SourceFile configured. Use xflow browse-source.'; return }
            if (-not (Test-Path $srcPath)) { Write-PmcStyled -Style 'Error' -Text ("Source file not found: {0}" -f $srcPath); return }
            if ($whatIf) { Write-PmcStyled -Style 'Info' -Text 'WhatIf: extracting values (no writes).' }
            $srcWb = Open-Workbook -Path $srcPath -ReadOnly
            $srcSheets = @{}
            foreach ($field in $cfg['FieldMappings'].Keys) {
                $map = $cfg['FieldMappings'][$field]
                $cell = [string](Get-XFlowMapVal $map 'Cell' '')
                $srcSheet = [string](Get-XFlowMapVal $map 'Sheet' (Get-XFlowCfgVal $cfg 'SourceSheet' ''))
                try {
                    if (-not $srcSheets.ContainsKey($srcSheet)) { $srcSheets[$srcSheet] = Get-Worksheet -Workbook $srcWb -Name $srcSheet }
                    $wsSrc = $srcSheets[$srcSheet]
                    $val = $wsSrc.Range($cell).Value2
                } catch { $val=$null; $errors += "Read failed: $field $srcSheet!$cell" }
                $extracted[$field] = $val
            }

            $destPath = [string](Get-XFlowCfgVal $cfg 'DestFile' '')
            if (-not $noExcel -and $destPath) {
                if (-not $whatIf) {
                    if (Test-Path $destPath) { $dstWb = Open-Workbook -Path $destPath } else { $dstWb = New-XFlowWorkbook -Path $destPath }
                    $dstSheets = @{}
                    foreach ($field in $cfg['FieldMappings'].Keys) {
                        $map = $cfg['FieldMappings'][$field]
                        $dest = [string](Get-XFlowMapVal $map 'DestCell' '')
                        $dstSheetName = [string](Get-XFlowMapVal $map 'DestSheet' (Get-XFlowCfgVal $cfg 'DestSheet' ''))
                        if ($dest -and $dest.Trim().Length -gt 0) {
                            try {
                                if (-not $dstSheets.ContainsKey($dstSheetName)) { $dstSheets[$dstSheetName] = Get-OrAddWorksheet -Workbook $dstWb -Name $dstSheetName }
                                $wsDst = $dstSheets[$dstSheetName]
                                $wsDst.Range($dest).Value2 = $extracted[$field]
                            } catch { $errors += "Write failed: $field $dstSheetName!$dest" }
                        }
                    }
                    try { Save-Workbook -Workbook $dstWb } catch { $errors += "Save failed: $destPath" }
                } else {
                    Write-PmcStyled -Style 'Info' -Text ("WhatIf: would update destination workbook: {0}" -f $destPath)
                }
            }
        }

        # Optional text export
        $exportPath = $null
        if ($format) {
            $ts = (Get-Date).ToString('yyyyMMdd_HHmmss')
            switch ($format.ToUpper()) {
                'CSV' { $exportPath = Export-XFlowToCsv -Data $extracted -OutPath ("exports/ExcelDataExport_{0}.csv" -f $ts) }
                'JSON' { $exportPath = Export-XFlowToJson -Data $extracted -OutPath ("exports/ExcelDataExport_{0}.json" -f $ts) }
                default { Write-PmcStyled -Style 'Warning' -Text ("Unsupported format: {0} (use csv|json)" -f $format) }
            }
        }

        # Record run
        $data = Get-PmcXFlowConfig
        $run = [ordered]@{
            Timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            SourceFile = (Get-XFlowCfgVal $cfg 'SourceFile' '(dry)')
            DestFile = (Get-XFlowCfgVal $cfg 'DestFile' '')
            FieldCount = @($cfg['FieldMappings'].Keys).Count
            Success = ($errors.Count -eq 0)
            Errors = $errors
            DurationMs = [int]((Get-Date) - $start).TotalMilliseconds
            ExportPath = $exportPath
            DryRun = $dry
        }
        $data.excelFlow['latestExtract'] = $extracted
        if (-not $data.excelFlow.PSObject.Properties['runs'] -or -not $data.excelFlow.runs) { $data.excelFlow['runs'] = @() }
        $data.excelFlow.runs += $run
        if (@($data.excelFlow.runs).Count -gt 20) { $data.excelFlow.runs = $data.excelFlow.runs[-20..-1] }
        Save-PmcData -Data $data -Action 'xflow:run'

        if ($run.Success) {
            Write-PmcStyled -Style 'Success' -Text ("XFlow {0} run completed. {1} fields." -f ($dry ? 'dry' : 'live'), $run.FieldCount)
            if ($exportPath) { Write-PmcStyled -Style 'Info' -Text ("Text export: {0}" -f $exportPath) }
        } else {
            Write-PmcStyled -Style 'Warning' -Text ("XFlow completed with errors: {0}" -f ($errors -join '; '))
        }
    } catch {
        Write-PmcStyled -Style 'Error' -Text ("Run failed: {0}" -f $_)
    } finally {
        if ($srcWb) { try { Close-Workbook -Workbook $srcWb } catch {} }
        if ($dstWb) { try { Close-Workbook -Workbook $dstWb } catch {} }
        try { Close-ExcelApp } catch {}
    }
}

function Import-PmcXFlowMappingsFromFile {
    param([PmcCommandContext]$Context)
    # Parse FreeText tokens like path:<file> or a single <file>
    $path = $null
    foreach ($t in $Context.FreeText) {
        if ($t -match '^(?i)path:(.+)$') { $path = $matches[1]; break }
        # If a token looks like a json file path and path: not used, take it
        if ($t -match '\.json$') { $path = $t; break }
    }
    if (-not $path) {
        # No path provided: open interactive file picker for JSON
        try {
            $start = (Get-Location).Path
            $picked = Invoke-PmcPathPicker -StartDir $start -Pick 'File' -Extensions @('*.json') -Title 'Select ExcelDataFlow settings.json'
            if ($picked) { $path = $picked }
        } catch { }
    }
    if (-not $path) { Write-PmcStyled -Style 'Info' -Text "Usage: xflow import-mappings path:<settings.json> (or choose interactively)"; return }
    if (-not (Test-Path $path)) { Write-PmcStyled -Style 'Error' -Text ("File not found: {0}" -f $path); return }
    try {
        $json = Get-Content -Path $path -Raw | ConvertFrom-Json -AsHashtable
        $spec = $null
        if ($json.ContainsKey('ExcelMappings')) { $spec = $json['ExcelMappings'] }
        else { $spec = $json }
        if (-not $spec -or -not $spec.ContainsKey('FieldMappings')) { Write-PmcStyled -Style 'Error' -Text 'No FieldMappings section found.'; return }

        $cfg = Get-PmcXFlowConfigData
        # Copy top-level fields if available
        foreach ($k in @('SourceFile','DestFile','SourceSheet','DestSheet')) { if ($spec.ContainsKey($k) -and $spec[$k]) { $cfg[$k] = [string]$spec[$k] } }

        # Exact FieldMappings transfer (no invention)
        $out = @{}
        foreach ($fname in $spec.FieldMappings.Keys) {
            $m = $spec.FieldMappings[$fname]
            $entry = @{}
            foreach ($mk in @('Sheet','Cell','DestCell','DestSheet')) {
                if ($m.PSObject.Properties[$mk] -and $m[$mk]) { $entry[$mk] = [string]$m[$mk] }
            }
            $out[$fname] = $entry
        }
        $cfg['FieldMappings'] = $out
        Save-PmcXFlowConfigData -Config $cfg
        Write-PmcStyled -Style 'Success' -Text ("Imported {0} field mappings from {1}" -f $out.Keys.Count, $path)
    } catch {
        Write-PmcStyled -Style 'Error' -Text ("Import failed: {0}" -f $_)
    }
}

function Export-PmcXFlowText {
    param([PmcCommandContext]$Context)
    $format = 'CSV'; if ($Context.Args.ContainsKey('format')) { $format = [string]$Context.Args['format'] }
    $data = Get-PmcXFlowConfig
    if (-not $data.excelFlow.PSObject.Properties['latestExtract'] -or -not $data.excelFlow.latestExtract) { Write-PmcStyled -Style 'Warning' -Text 'No latest extract found. Run xflow run first.'; return }
    $extracted = $data.excelFlow.latestExtract
    $ts = (Get-Date).ToString('yyyyMMdd_HHmmss')
    switch ($format.ToUpper()) {
        'CSV'  { $out = Export-XFlowToCsv -Data $extracted -OutPath ("exports/ExcelDataExport_{0}.csv" -f $ts) }
        'JSON' { $out = Export-XFlowToJson -Data $extracted -OutPath ("exports/ExcelDataExport_{0}.json" -f $ts) }
        default { Write-PmcStyled -Style 'Warning' -Text ("Unsupported format: {0} (use csv|json)" -f $format); return }
    }
    Write-PmcStyled -Style 'Success' -Text ("Exported {0} fields to {1}" -f $extracted.Keys.Count, $out)
}

function Set-PmcXFlowLatestFromFile {
    param([PmcCommandContext]$Context)
    if (-not $Context.Args.ContainsKey('values')) { Write-PmcStyled -Style 'Info' -Text "Usage: xflow set-latest values:<path.json>"; return }
    $path = [string]$Context.Args['values']
    if (-not (Test-Path $path)) { Write-PmcStyled -Style 'Error' -Text ("File not found: {0}" -f $path); return }
    try {
        $raw = Get-Content -Path $path -Raw | ConvertFrom-Json -AsHashtable
        $dict = if ($raw.ContainsKey('Data')) { $raw['Data'] } else { $raw }
        if (-not ($dict -is [hashtable])) { Write-PmcStyled -Style 'Error' -Text 'Values JSON must be an object or contain a Data object.'; return }
        $data = Get-PmcXFlowConfig
        $data.excelFlow['latestExtract'] = $dict
        Save-PmcData -Data $data -Action 'xflow:set-latest'
        Write-PmcStyled -Style 'Success' -Text ("latestExtract set from {0}. Fields: {1}" -f $path, $dict.Keys.Count)
    } catch {
        Write-PmcStyled -Style 'Error' -Text ("Failed to set latest: {0}" -f $_)
    }
}

function Show-PmcXFlowConfig {
    param([PmcCommandContext]$Context)
    $cfg = Get-PmcXFlowConfigData
    if (-not ($cfg -is [hashtable])) { Write-PmcStyled -Style 'Info' -Text 'No xflow config found.'; return }
    $sf = [string](Get-XFlowCfgVal $cfg 'SourceFile' '')
    $ss = [string](Get-XFlowCfgVal $cfg 'SourceSheet' '')
    $df = [string](Get-XFlowCfgVal $cfg 'DestFile' '')
    $ds = [string](Get-XFlowCfgVal $cfg 'DestSheet' '')
    $fm = $null; if ($cfg.ContainsKey('FieldMappings')) { $fm = $cfg['FieldMappings'] } else { $fm = @{} }
    $count = @($fm.Keys).Count
    Write-PmcStyled -Style 'Title' -Text 'XFlow Configuration'
    Write-Host ("  SourceFile  : {0}" -f ($sf ? $sf : '(none)'))
    Write-Host ("  SourceSheet : {0}" -f ($ss ? $ss : '(none)'))
    Write-Host ("  DestFile    : {0}" -f ($df ? $df : '(none)'))
    Write-Host ("  DestSheet   : {0}" -f ($ds ? $ds : '(none)'))
    Write-Host ("  Fields      : {0}" -f $count)
    if ($count -gt 0) {
        Write-PmcStyled -Style 'Border' -Text ("─" * 50)
        $names = $fm.Keys | Sort-Object | Select-Object -First 10
        foreach ($n in $names) {
            $m = $fm[$n]
            $sheet = [string](Get-XFlowMapVal $m 'Sheet' $ss)
            $cell  = [string](Get-XFlowMapVal $m 'Cell' '')
            $dsh   = [string](Get-XFlowMapVal $m 'DestSheet' $ds)
            $dcl   = [string](Get-XFlowMapVal $m 'DestCell' '')
            Write-Host ("  {0,-20} {1,-12} {2,-8} -> {3,-12} {4}" -f $n, $sheet, $cell, $dsh, $dcl)
        }
        if ($count -gt 10) { Write-PmcStyled -Style 'Muted' -Text ("  ... and {0} more" -f ($count - 10)) }
    }
}


# END FILE: ./module/Pmc.Strict/src/ExcelFlowLite.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/Execution.ps1
# SIZE: 21.31 KB
# MODIFIED: 2025-09-24 05:28:58
# ================================================================================

# Execution pipeline for domain-action commands

function Set-PmcContextDefaults {
    param([PmcCommandContext]$Context)

    # Apply default values based on domain/action patterns
    # This function sets defaults for common arguments to simplify command usage

    if (-not $Context.Args) { $Context.Args = @{} }
    if (-not $Context.FreeText) { $Context.FreeText = @() }

    # Domain-specific defaults
    switch ($Context.Domain) {
        'task' {
            # For task operations, ensure priority defaults exist
            if ($Context.Action -in @('add', 'update', 'edit') -and -not $Context.Args.ContainsKey('priority')) {
                $Context.Args['priority'] = 0  # Default priority
            }
        }
        'project' {
            # Project operations may need defaults
            if ($Context.Action -eq 'add' -and -not $Context.Args.ContainsKey('status')) {
                $Context.Args['status'] = 'active'  # Default status
            }
        }
        'time' {
            # Time logging defaults
            if ($Context.Action -eq 'log' -and -not $Context.Args.ContainsKey('date')) {
                $Context.Args['date'] = (Get-Date).ToString('yyyy-MM-dd')  # Default to today
            }
        }
    }
}

function Normalize-PmcContextFields {
    param([PmcCommandContext]$Context)
    if (-not $Context -or -not $Context.Domain) { return }
    try {
        $schemas = Get-PmcFieldSchemasForDomain -Domain $Context.Domain
        foreach ($k in @($Context.Args.Keys)) {
            if ($schemas.ContainsKey($k)) {
                $sch = $schemas[$k]
                if ($sch.ContainsKey('Normalize') -and $sch.Normalize) {
                    try {
                        $Context.Args[$k] = & $sch.Normalize ([string]$Context.Args[$k])
                    } catch {
                        # Leave raw value; validation will surface the error later
                    }
                }
            }
        }
    } catch { }
}

function Resolve-PmcHandler {
    param([string]$Domain,[string]$Action)
    if (-not $Script:PmcCommandMap.ContainsKey($Domain)) { return $null }
    $map = $Script:PmcCommandMap[$Domain]
    if (-not $map.ContainsKey($Action)) { return $null }
    return $map[$Action]
}

function Resolve-PmcProjectFromTokens {
    param(
        [string[]] $Tokens,
        [int] $StartIndex
    )
    # Returns a hashtable: @{ Name = <string>; Consumed = <int> }
    # If no resolution, returns @{ Name=$null; Consumed=1 } (consume only the '@...' token)
    $result = @{ Name = $null; Consumed = 1 }
    if ($StartIndex -lt 0 -or $StartIndex -ge $Tokens.Count) { return $result }
    $first = $Tokens[$StartIndex]
    if (-not ($first -match '^@(.+)$')) { return $result }

    $initial = $matches[1]
    $candidates = @()
    try {
        $data = Get-PmcDataAlias
        $projects = @($data.projects | ForEach-Object { [string]$_.name })
        if (-not $projects) { return $result }

        # Greedily extend with following plain tokens (no prefixes, not '--')
        $bestName = $null
        $bestLen = 1
        $current = $initial
        if ($projects -contains $current) { $bestName = $current; $bestLen = 1 }

        for ($i = $StartIndex + 1; $i -lt $Tokens.Count; $i++) {
            $t = $Tokens[$i]
            if ($t -eq '--' -or $t -match '^@' -or $t -match '^(p[1-3])$' -or $t -match '^due:' -or $t -match '^#' -or $t -match '^-#') {
                break
            }
            $current = "$current $t"
            if ($projects -contains $current) { $bestName = $current; $bestLen = ($i - $StartIndex + 1) }
        }

        if ($bestName) {
            $result.Name = $bestName
            $result.Consumed = $bestLen
            return $result
        }
    } catch { }

    return $result
}

function Parse-PmcArgsFromTokens {
    param(
        [string[]] $Tokens,
        [int] $StartIndex = 0
    )

    $args = @{}
    $free = @()
    $seenPlain = $false
    for ($i = $StartIndex; $i -lt $Tokens.Count; $i++) {
        $t = $Tokens[$i]
        if ($seenPlain) { $free += $t; continue }
        if ($t -eq '--') { $seenPlain = $true; continue }
        if ($t -match '^@') {
            $res = Resolve-PmcProjectFromTokens -Tokens $Tokens -StartIndex $i
            if ($res.Name) { $args['project'] = $res.Name; $i += ($res.Consumed - 1); continue }
            if ($t -match '^@(.+)$') { $args['project'] = $matches[1]; continue }
        }
        if ($t -eq '-i') { $args['interactive'] = $true; continue }
        if ($t -match '^(?i)task:(\d+)$') { $args['taskId'] = [int]$matches[1]; continue }
        if ($t -match '^(p[1-3])$') { $args['priority'] = $matches[1]; continue }
        if ($t -match '^due:(.+)$') { $args['due'] = $matches[1]; continue }
        if ($t -match '^#(.+)$' -or $t -match '^\+(.+)$') { if (-not $args.ContainsKey('tags')) { $args['tags']=@() }; $args['tags'] += $matches[1]; continue }
        if ($t -match '^-#?(.+)$') { if (-not $args.ContainsKey('removeTags')) { $args['removeTags']=@() }; $args['removeTags'] += $matches[1]; continue }
        $seenPlain = $true
        $free += $t
    }
    return @{ Args = $args; Free = $free }
}

function ConvertTo-PmcIdSet {
    param([string]$text)
    $ids = @()
    foreach ($part in ($text -split ',')) {
        $p = $part.Trim()
        if ($p -match '^(\d+)-(\d+)$') { $a=[int]$matches[1]; $b=[int]$matches[2]; if ($a -le $b) { for ($i=$a; $i -le $b; $i++) { $ids += $i } } else { for ($i=$a; $i -ge $b; $i--) { $ids += $i } } }
        elseif ($p -match '^\d+$') { $ids += [int]$p }
    }
    return @($ids | Select-Object -Unique)
}

function ConvertTo-PmcContext {
    param([string[]]$Tokens)
    if ($Tokens.Count -lt 1) { return @{ Success=$false; Error='Empty command' } }

    # Special handling for 'help' so users can type: 'help', 'help guide [topic]', 'help examples [topic]', 'help query', 'help domain <d>', 'help command <d> <a>'
    if ($Tokens[0].ToLower() -eq 'help') {
        if ($Tokens.Count -eq 1) {
            $ctx = [PmcCommandContext]::new('help','show')
            $ctx.Raw = 'help show'
            return @{ Success=$true; Context=$ctx; Handler='Show-PmcSmartHelp' }
        } elseif ($Tokens.Count -ge 2) {
            $sub = $Tokens[1].ToLower()
            switch ($sub) {
                'guide' {
                    $ctx = [PmcCommandContext]::new('help','guide')
                    $ctx.Raw = ($Tokens -join ' ')
                    if ($Tokens.Count -ge 3) { $ctx.FreeText = @($Tokens[2]) }
                    return @{ Success=$true; Context=$ctx; Handler='Show-PmcHelpGuide' }
                }
                'search' {
                    $ctx = [PmcCommandContext]::new('help','search')
                    $ctx.Raw = ($Tokens -join ' ')
                    if ($Tokens.Count -ge 3) { $ctx.FreeText = @(($Tokens[2..($Tokens.Count-1)] -join ' ')) }
                    else { $ctx.FreeText = @('') }
                    return @{ Success=$true; Context=$ctx; Handler='Show-PmcHelpSearch' }
                }
                'examples' {
                    $ctx = [PmcCommandContext]::new('help','examples')
                    $ctx.Raw = ($Tokens -join ' ')
                    if ($Tokens.Count -ge 3) { $ctx.FreeText = @($Tokens[2]) }
                    return @{ Success=$true; Context=$ctx; Handler='Show-PmcHelpExamples' }
                }
                'query' {
                    $ctx = [PmcCommandContext]::new('help','query')
                    $ctx.Raw = ($Tokens -join ' ')
                    return @{ Success=$true; Context=$ctx; Handler='Show-PmcHelpQuery' }
                }
                'domain' {
                    $ctx = [PmcCommandContext]::new('help','domain')
                    $ctx.Raw = ($Tokens -join ' ')
                    if ($Tokens.Count -ge 3) { $ctx.FreeText = @($Tokens[2]) }
                    return @{ Success=$true; Context=$ctx; Handler='Show-PmcHelpDomain' }
                }
                'command' {
                    $ctx = [PmcCommandContext]::new('help','command')
                    $ctx.Raw = ($Tokens -join ' ')
                    if ($Tokens.Count -ge 4) { $ctx.FreeText = @($Tokens[2], $Tokens[3]) }
                    return @{ Success=$true; Context=$ctx; Handler='Show-PmcHelpCommand' }
                }
                default {
                    if ($Tokens.Count -eq 2) {
                        # Interpret as: help domain <domain>
                        $ctx = [PmcCommandContext]::new('help','domain')
                        $ctx.Raw = ($Tokens -join ' ')
                        $ctx.FreeText = @($Tokens[1])
                        return @{ Success=$true; Context=$ctx; Handler='Show-PmcHelpDomain' }
                    } else {
                        # Interpret as: help command <domain> <action>
                        $ctx = [PmcCommandContext]::new('help','command')
                        $ctx.Raw = ($Tokens -join ' ')
                        $ctx.FreeText = @($Tokens[1], $Tokens[2])
                        return @{ Success=$true; Context=$ctx; Handler='Show-PmcHelpCommand' }
                    }
                }
            }
        }
    }

    # Treat first token matching a shortcut as a shortcut command (with args)
    $firstToken = $Tokens[0].ToLower()
    if ($Script:PmcShortcutMap.ContainsKey($firstToken)) {
        $fn = $Script:PmcShortcutMap[$firstToken]
        $ctx = [PmcCommandContext]::new('shortcut', $firstToken)
        $ctx.Raw = ($Tokens -join ' ')
        $parsedArgs = Parse-PmcArgsFromTokens -Tokens $Tokens -StartIndex 1
        $ctx.Args = $parsedArgs.Args
        $ctx.FreeText = $parsedArgs.Free
        return @{ Success=$true; Context=$ctx; Handler=$fn }
    }

    # No fallback here — shortcuts must be initialized by the module loader

    # Standard domain-action parsing
    if ($Tokens.Count -lt 2) {
        return @{ Success=$false; Error='Missing action. Use: <domain> <action> [...] or use shortcuts like: add, done, list' }
    }
    $domain = $Tokens[0].ToLower()
    $action = $Tokens[1].ToLower()
    $fn = Resolve-PmcHandler -Domain $domain -Action $action
    if (-not $fn) {
        if (-not $Script:PmcCommandMap.ContainsKey($domain)) {
            return @{ Success=$false; Error="Unknown domain '$domain'" }
        }
        return @{ Success=$false; Error="Unknown action '$action' for domain '$domain'" }
    }
    $ctx = [PmcCommandContext]::new($domain,$action)
    $ctx.Raw = ($Tokens -join ' ')
    # Use AST-based parsing instead of regex-heavy token parsing
    $commandText = ($Tokens -join ' ')

    # Try AST-based parsing first
    try {
        if (Get-Command ConvertTo-PmcCommandAst -ErrorAction SilentlyContinue) {
            $astResult = ConvertTo-PmcCommandAst -CommandText $commandText
            $ctx.Args = $astResult.Args
            $ctx.FreeText = $astResult.FreeText
            Write-PmcDebug -Level 2 -Category 'Execution' -Message "Using AST-based argument parsing"
        } else {
            # Fallback to legacy parsing if AST not available
            $rest = @($Tokens | Select-Object -Skip 2)
            $parsed = Parse-PmcArgsFromTokens -Tokens $rest -StartIndex 0
            $ctx.Args = $parsed.Args
            $ctx.FreeText = $parsed.Free
            Write-PmcDebug -Level 2 -Category 'Execution' -Message "Using legacy token parsing"
        }
    } catch {
        Write-PmcDebug -Level 1 -Category 'Execution' -Message "AST parsing failed, using legacy: $_"
        # Fallback to legacy parsing
        $rest = @($Tokens | Select-Object -Skip 2)
        $parsed = Parse-PmcArgsFromTokens -Tokens $rest -StartIndex 0
        $ctx.Args = $parsed.Args
        $ctx.FreeText = $parsed.Free
    }
    # Normalize known field values using Field Schemas
    Normalize-PmcContextFields -Context $ctx
    return @{ Success=$true; Context=$ctx; Handler=$fn }
}

function Invoke-PmcCommand {
    param([Parameter(Mandatory=$true)][string]$Buffer)

    Write-PmcDebugCommand -Command $Buffer -Status 'START'

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        # Expand user-defined aliases before tokenization
        # Check for alias expansion
        if (Get-Command Expand-PmcUserAliases -ErrorAction SilentlyContinue) {
            $Buffer = Expand-PmcUserAliases -Buffer $Buffer
        }

        $tokens = ConvertTo-PmcTokens $Buffer
        Write-PmcDebug -Level 2 -Category 'PARSER' -Message "Tokenized command" -Data @{ TokenCount = $tokens.Count; Tokens = $tokens }

        $parsed = ConvertTo-PmcContext $tokens
        if (-not $parsed.Success) {
            Write-PmcDebugCommand -Command $Buffer -Status 'PARSE_ERROR' -Context @{ Error = $parsed.Error } -Timing $stopwatch.ElapsedMilliseconds
            Write-PmcStyled -Style 'Error' -Text "Error: $($parsed.Error)"
            return
        }

        $fn = $parsed.Handler
        $ctx = $parsed.Context

        Write-PmcDebug -Level 2 -Category 'PARSER' -Message "Context parsed" -Data @{ Domain = $ctx.Domain; Action = $ctx.Action; ArgCount = $ctx.Args.Count; Handler = $fn }

        try {
            Set-PmcContextDefaults -Context $ctx
            Write-PmcDebug -Level 3 -Category 'COERCION' -Message "Context coerced" -Data @{ Args = $ctx.Args }
        } catch {
            Write-PmcDebug -Level 1 -Category 'COERCION' -Message "Coercion failed: $_"
        }

        try {
            $ok = Test-PmcContext -Context $ctx
            if (-not $ok) {
                Write-PmcDebugCommand -Command $Buffer -Status 'VALIDATION_ERROR' -Context @{ Domain = $ctx.Domain; Action = $ctx.Action } -Timing $stopwatch.ElapsedMilliseconds
                return
            }
            Write-PmcDebug -Level 3 -Category 'VALIDATION' -Message "Context validated successfully"
        } catch {
            Write-PmcDebug -Level 1 -Category 'VALIDATION' -Message "Validation failed: $_"
        }

        if (Get-Command -Name $fn -ErrorAction SilentlyContinue) {
            Write-PmcDebug -Level 2 -Category 'Execution' -Message "About to execute function: $fn"
            $cmdInfo = Get-Command -Name $fn -ErrorAction SilentlyContinue
            $srcFile = $null
            try { if ($cmdInfo -and $cmdInfo.CommandType -eq 'Function' -and $cmdInfo.ScriptBlock) { $srcFile = $cmdInfo.ScriptBlock.File } } catch { }
            Write-PmcDebug -Level 2 -Category 'EXECUTION' -Message "Invoking handler: $fn" -Data @{ Source = ($srcFile ?? '(unknown)') }

            & $fn -Context $ctx

            $stopwatch.Stop()
            Write-PmcDebugCommand -Command $Buffer -Status 'SUCCESS' -Context @{ Domain = $ctx.Domain; Action = $ctx.Action; Handler = $fn } -Timing $stopwatch.ElapsedMilliseconds
        } else {
            Write-PmcDebugCommand -Command $Buffer -Status 'NO_HANDLER' -Context @{ Domain = $ctx.Domain; Action = $ctx.Action; Handler = $fn } -Timing $stopwatch.ElapsedMilliseconds
            Write-PmcStyled -Style 'Warning' -Text "Not implemented: $($ctx.Domain) $($ctx.Action)"
        }

    } catch {
        $stopwatch.Stop()
        Write-PmcDebugCommand -Command $Buffer -Status 'ERROR' -Context @{ Error = $_.ToString(); Exception = $_.Exception.GetType().Name } -Timing $stopwatch.ElapsedMilliseconds
        Write-PmcStyled -Style 'Error' -Text "Command execution failed: $_"
    }
}

function ConvertTo-PmcContextType {
    param([PmcCommandContext]$Context)
    if (-not $Context) { return }
    $key = "$($Context.Domain) $($Context.Action)".ToLower()
    $schema = if ($Script:PmcParameterMap.ContainsKey($key)) { $Script:PmcParameterMap[$key] } else { @() }
    if (-not $schema -or @($schema).Count -eq 0) { return }
    # TaskID: parse first free text token to ids if applicable
    $needsId = $false
    foreach ($def in $schema) { if ($def['Type'] -eq 'TaskID') { $needsId = $true; break } }
    if ($needsId -and @($Context.FreeText).Count -ge 1) {
        $t0 = $Context.FreeText[0]
        if ($t0 -match '^[0-9,\-]+$') {
            $set = ConvertTo-PmcIdSet $t0
            if (@($set).Count -gt 0) { $Context.Args['ids'] = $set }
        }
        elseif ($t0 -match '^\d+$') {
            # list index handled in handlers via map; still pass as singleton id candidate
            $Context.Args['ids'] = @([int]$t0)
        }
    }
    # Normalize priority string to int for convenience (add priorityInt) after schema normalization
    if ($Context.Args.ContainsKey('priority')) {
        $pv = [string]$Context.Args['priority']
        if ($pv -match '^[1-3]$') { $Context.Args['priorityInt'] = [int]$pv }
    }
    # Due already normalized by schema; add convenience dueIso if matches ISO
    if ($Context.Args.ContainsKey('due')) {
        $dv = [string]$Context.Args['due']
        if ($dv -match '^\d{4}-\d{2}-\d{2}$') { $Context.Args['dueIso'] = $dv }
    }

    # Resolve project names when schema expects a ProjectName
    $needsProject = $false
    foreach ($def in $schema) { if ($def['Type'] -eq 'ProjectName') { $needsProject = $true; break } }
    if ($needsProject -and $Context.Args.ContainsKey('project')) {
        try { $data = Get-PmcDataAlias; $p = Resolve-Project -Data $data -Name $Context.Args['project']; if ($p) { $Context.Args['projectNameResolved'] = $p.name } } catch {
            # Project resolution failed - continue without resolved name
        }
    }

    # Parse duration tokens for commands that expect Duration
    $needsDuration = $false
    foreach ($def in $schema) { if ($def['Type'] -eq 'Duration') { $needsDuration = $true; break } }
    if ($needsDuration) {
        $durTok = $null
        foreach ($t in $Context.FreeText) {
            if ($t -match '^\d+(?:\.\d+)?$' -or $t -match '^\d+(?:\.\d+)?h$' -or $t -match '^\d+m$') { $durTok = $t; break }
        }
        if ($durTok) {
            try { $mins = ConvertTo-PmcDurationMinutes $durTok; if ($mins -gt 0) { $Context.Args['durationMinutes'] = $mins } } catch {
                # Duration parsing failed - continue without duration
            }
        }
    }
}

function Test-PmcContext {
    param([PmcCommandContext]$Context)
    $key = "$($Context.Domain) $($Context.Action)".ToLower()
    $schema = if ($Script:PmcParameterMap.ContainsKey($key)) { $Script:PmcParameterMap[$key] } else { @() }
    if (-not $schema -or @($schema).Count -eq 0) { return $true }
    $errors = @()
    # Check required schema elements
    foreach ($def in $schema) {
        $name = [string]$def['Name']
        $type = [string]$def['Type']
        $required = $false; try { $required = [bool]$def['Required'] } catch {
            # Schema definition access failed - assume not required
        }
        if (-not $required) { continue }
        switch ($type) {
            'FreeText' {
                if (-not $Context.FreeText -or @($Context.FreeText).Count -eq 0) { $errors += "Missing required text" }
            }
            'TaskID' {
                $hasIds = ($Context.Args.ContainsKey('ids') -and @($Context.Args['ids']).Count -gt 0)
                $hasToken = (@($Context.FreeText).Count -ge 1)
                if (-not $hasIds -and -not $hasToken) { $errors += "Missing required id(s)" }
            }
            'ProjectName' {
                if (-not $Context.Args.ContainsKey('project')) { $errors += "Missing required @project" }
            }
            'Priority' {
                if (-not $Context.Args.ContainsKey('priority') -and -not $Context.Args.ContainsKey('priorityInt')) { $errors += "Missing required priority (p1/p2/p3)" }
            }
            'DateString' {
                if (-not $Context.Args.ContainsKey('due') -and -not $Context.Args.ContainsKey('dueIso')) { $errors += "Missing required date" }
            }
            'DateRange' {
                # If required, ensure at least one recognizable token exists
                $has = $false
                foreach ($t in $Context.FreeText) {
                    if ($t -match '^(?i)today|yesterday|week$' -or $t -match '^\d{4}-\d{2}-\d{2}$') { $has=$true; break }
                }
                if (-not $has) { $errors += "Missing required date range" }
            }
            'Duration' {
                if (-not $Context.Args.ContainsKey('durationMinutes')) {
                    $hasLike = $false
                    foreach ($t in $Context.FreeText) { if ($t -match '^\d+(?:\.\d+)?$' -or $t -match '^\d+(?:\.\d+)?h$' -or $t -match '^\d+m$') { $hasLike=$true; break } }
                    if (-not $hasLike) { $errors += "Missing required duration (e.g., 1.5 hours or 90m)" }
                }
            }
            default { }
        }
    }
    # Field-level validation via Field Schemas
    try {
        $schemas = Get-PmcFieldSchemasForDomain -Domain $Context.Domain
        foreach ($k in @($Context.Args.Keys)) {
            if ($schemas.ContainsKey($k)) {
                $sch = $schemas[$k]
                if ($sch.ContainsKey('Validate') -and $sch.Validate) {
                    try { & $sch.Validate ([string]$Context.Args[$k]) | Out-Null } catch { $errors += $_.Exception.Message }
                }
            }
        }
    } catch { }

    # Basic tag validation if tags present
    if ($Context.Args.ContainsKey('tags')) {
        foreach ($tag in @($Context.Args['tags'])) { if (-not $tag -or ($tag -match '\s')) { $errors += ("Invalid tag '{0}'" -f $tag) } }
    }
    if (@($errors).Count -gt 0) {
        foreach ($e in $errors) { Write-PmcStyled -Style 'Error' -Text ("Error: {0}" -f $e) }
        return $false
    }
    return $true
}

Export-ModuleMember -Function Set-PmcContextDefaults, Normalize-PmcContextFields, Resolve-PmcHandler, Resolve-PmcProjectFromTokens, Parse-PmcArgsFromTokens, ConvertTo-PmcIdSet, ConvertTo-PmcContext, Invoke-PmcCommand, ConvertTo-PmcContextType, Test-PmcContext


# END FILE: ./module/Pmc.Strict/src/Execution.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/FieldSchemas.ps1
# SIZE: 12.67 KB
# MODIFIED: 2025-09-22 15:23:10
# ================================================================================

# Domain Field Schemas for PMC (authoritative field rules)

Set-StrictMode -Version Latest

function Get-PmcFieldSchemasForDomain {
    param([Parameter(Mandatory=$true)][string]$Domain)

    switch ($Domain.ToLower()) {
        'task' {
            return @{
                'id' = @{
                    Name = 'id'
                    Editable = $false
                    Sensitive = $true
                    Hint = '#'
                    DefaultWidth = 4
                    MinWidth = 3
                    DisplayFormat = { param($val) if ($null -ne $val) { [string]$val } else { '' } }
                }
                'text' = @{
                    Name = 'text'
                    Editable = $true
                    Sensitive = $false
                    Hint = 'task text'
                    DefaultWidth = 40
                    MinWidth = 20
                    Normalize = { param([string]$v) return ($v ?? '') }
                    Validate = { param([string]$v) return $true }
                    DisplayFormat = { param($val) if ($null -ne $val) { [string]$val } else { '' } }
                }
                'project' = @{
                    Name = 'project'
                    Editable = $false
                    Sensitive = $true
                    Hint = '@project'
                    DefaultWidth = 12
                    MinWidth = 10
                    Normalize = { param([string]$v) return ($v.TrimStart('@').Trim()) }
                    Validate = { param([string]$v) return $true }
                    DisplayFormat = { param($val) if ($null -ne $val) { [string]$val } else { '' } }
                }
                'due' = @{
                    Name = 'due'
                    Editable = $true
                    Sensitive = $false
                    Hint = 'Many formats: yyyymmdd, mmdd, today, eow, eom, +3, 1m, yyyy/mm/dd, etc.'
                    DefaultWidth = 10
                    MinWidth = 8
                    Normalize = {
                        param([string]$v)
                        $x = ($v ?? '').Trim()
                        if ($x -eq '') { return '' }

                        # Already correct format
                        if ($x -match '^\d{4}-\d{2}-\d{2}$') { return $x }

                        $today = Get-Date
                        $currentYear = $today.Year

                        # Special keywords
                        switch -Regex ($x) {
                            '^(?i)today$' { return $today.Date.ToString('yyyy-MM-dd') }
                            '^(?i)tomorrow$' { return $today.Date.AddDays(1).ToString('yyyy-MM-dd') }
                            '^(?i)eow$' {
                                # End of week (Sunday)
                                $daysUntilSunday = (7 - [int]$today.DayOfWeek) % 7
                                if ($daysUntilSunday -eq 0) { $daysUntilSunday = 7 }
                                return $today.Date.AddDays($daysUntilSunday).ToString('yyyy-MM-dd')
                            }
                            '^(?i)eom$' {
                                # End of month
                                $lastDay = [DateTime]::DaysInMonth($today.Year, $today.Month)
                                return (New-Object DateTime($today.Year, $today.Month, $lastDay)).ToString('yyyy-MM-dd')
                            }
                            '^[+-]\d+$' {
                                # +3, -5 (days from today)
                                $days = [int]$x
                                return $today.Date.AddDays($days).ToString('yyyy-MM-dd')
                            }
                            '^(\d+)[dmwy]$' {
                                # 1d, 2w, 3m, 1y (relative from today)
                                $matches = [regex]::Match($x, '^(\d+)([dmwy])$')
                                $num = [int]$matches.Groups[1].Value
                                $unit = $matches.Groups[2].Value.ToLower()
                                $targetDate = switch ($unit) {
                                    'd' { $today.AddDays($num) }
                                    'w' { $today.AddDays($num * 7) }
                                    'm' { $today.AddMonths($num) }
                                    'y' { $today.AddYears($num) }
                                }
                                return $targetDate.Date.ToString('yyyy-MM-dd')
                            }
                            '^(\d{1,2})(\d{2})$' {
                                # mmdd format (current year assumed)
                                $matches = [regex]::Match($x, '^(\d{1,2})(\d{2})$')
                                $month = [int]$matches.Groups[1].Value
                                $day = [int]$matches.Groups[2].Value
                                if ($month -lt 1 -or $month -gt 12) { throw "Invalid month: $month" }
                                if ($day -lt 1 -or $day -gt 31) { throw "Invalid day: $day" }
                                return (New-Object DateTime($currentYear, $month, $day)).ToString('yyyy-MM-dd')
                            }
                            '^(\d{4})(\d{2})(\d{2})$' {
                                # yyyymmdd format
                                $matches = [regex]::Match($x, '^(\d{4})(\d{2})(\d{2})$')
                                $year = [int]$matches.Groups[1].Value
                                $month = [int]$matches.Groups[2].Value
                                $day = [int]$matches.Groups[3].Value
                                if ($month -lt 1 -or $month -gt 12) { throw "Invalid month: $month" }
                                if ($day -lt 1 -or $day -gt 31) { throw "Invalid day: $day" }
                                return (New-Object DateTime($year, $month, $day)).ToString('yyyy-MM-dd')
                            }
                        }

                        # Try standard date parsing (yyyy/mm/dd, yy-mm-dd, etc.)
                        $dt = $null
                        if ([DateTime]::TryParse($x, [Globalization.CultureInfo]::CurrentCulture, [Globalization.DateTimeStyles]::None, [ref]$dt)) {
                            return $dt.ToString('yyyy-MM-dd')
                        }

                        throw "Date format not recognized. Try: yyyymmdd, mmdd, today, eow, eom, +3, 1m, or standard formats like yyyy/mm/dd"
                    }
                    Validate = {
                        param([string]$v)
                        if ($v -eq '') { return $true }
                        if ($v -match '^\d{4}-\d{2}-\d{2}$') { return $true }
                        throw "Due must be yyyy-MM-dd"
                    }
                    DisplayFormat = {
                        param($val)
                        $s = [string]$val
                        if (-not $s) { return '' }
                        try { $d=[datetime]::ParseExact($s,'yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture); return $d.ToString('MM/dd') } catch { return $s }
                    }
                }
                'priority' = @{
                    Name = 'priority'
                    Editable = $true
                    Sensitive = $false
                    Hint = '1..3 (e.g., 2 or P2)'
                    DefaultWidth = 3
                    MinWidth = 3
                    Normalize = {
                        param([string]$v)
                        $x = ($v ?? '').Trim()
                        if ($x -eq '') { return '' }
                        if ($x -match '^[Pp]([1-3])$') { return $matches[1] }
                        if ($x -match '^[1-3]$') { return $x }
                        throw "Priority must be 1..3 (e.g., 2 or P2)"
                    }
                    Validate = {
                        param([string]$v)
                        if ($v -eq '') { return $true }
                        if ($v -match '^[1-3]$') { return $true }
                        throw "Priority must be 1..3"
                    }
                    DisplayFormat = { param($val) if ($val) { 'P' + [string]$val } else { '' } }
                }
            }
        }
        'project' {
            return @{
                'name' = @{
                    Name='name'; Editable=$false; Sensitive=$false; Hint='project name'; DefaultWidth=20; MinWidth=12
                    DisplayFormat = { param($v) if ($null -ne $v) { [string]$v } else { '' } }
                }
                'description' = @{
                    Name='description'; Editable=$false; Sensitive=$false; Hint='description'; DefaultWidth=30; MinWidth=15
                    DisplayFormat = { param($v) if ($null -ne $v) { [string]$v } else { '' } }
                }
                'task_count' = @{
                    Name='task_count'; Editable=$false; Sensitive=$false; Hint='tasks'; DefaultWidth=6; MinWidth=4
                    DisplayFormat = { param($v) if ($v -ne $null) { [string]$v } else { '' } }
                }
                'completion' = @{
                    Name='completion'; Editable=$false; Sensitive=$false; Hint='% done'; DefaultWidth=6; MinWidth=3
                    Normalize = { param([string]$v) ($v ?? '').Trim('%') }
                    Validate = { param([string]$v) if ($v -eq '' -or $v -match '^\d{1,3}$') { return $true } throw 'completion must be 0..100' }
                    DisplayFormat = { param($v) if ($v -ne $null -and $v -ne '') { ([string]$v).Trim('%') + '%' } else { '' } }
                }
            }
        }
        'timelog' {
            return @{
                'date' = @{
                    Name='date'; Editable=$true; Sensitive=$false; Hint='yyyy-MM-dd'; DefaultWidth=10; MinWidth=8
                    Normalize = {
                        param([string]$v)
                        $x = ($v ?? '').Trim(); if ($x -eq '') { return '' }
                        if ($x -match '^\d{4}-\d{2}-\d{2}$') { return $x }
                        $dt = $null
                        if ([DateTime]::TryParse($x, [Globalization.CultureInfo]::CurrentCulture, [Globalization.DateTimeStyles]::None, [ref]$dt)) { return $dt.ToString('yyyy-MM-dd') }
                        throw 'Date must be yyyy-MM-dd'
                    }
                    Validate = { param([string]$v) if ($v -eq '' -or $v -match '^\d{4}-\d{2}-\d{2}$') { return $true } throw 'Date must be yyyy-MM-dd' }
                    DisplayFormat = { param($v) if ($v) { try { ([datetime]::ParseExact([string]$v,'yyyy-MM-dd',[Globalization.CultureInfo]::InvariantCulture)).ToString('MM/dd') } catch { [string]$v } } else { '' } }
                }
                'project' = @{
                    Name='project'; Editable=$false; Sensitive=$true; Hint='@project'; DefaultWidth=15; MinWidth=10
                    DisplayFormat = { param($v) if ($null -ne $v) { [string]$v } else { '' } }
                }
                'duration' = @{
                    Name='duration'; Editable=$true; Sensitive=$false; Hint='minutes or h/m (e.g., 1.5h, 90m)'; DefaultWidth=8; MinWidth=6
                    Normalize = {
                        param([string]$v)
                        $x = ($v ?? '').Trim(); if ($x -eq '') { return '' }
                        if ($x -match '^(\d+(?:\.\d+)?)h$') { return ([int]([double]$matches[1] * 60)).ToString() }
                        if ($x -match '^(\d+)m$') { return $matches[1] }
                        if ($x -match '^(\d+)$') { return $x }
                        throw 'Duration must be minutes or h/m format'
                    }
                    Validate = { param([string]$v) if ($v -eq '' -or $v -match '^\d+$') { return $true } throw 'Duration must be whole minutes' }
                    DisplayFormat = { param($v)
                        if ($v -match '^\d+$') {
                            $mins=[int]$v
                            if ($mins -ge 60) {
                                return '{0}h {1}m' -f ([int]($mins/60)), ($mins%60)
                            } else {
                                return $mins.ToString() + 'm'
                            }
                        } else {
                            return [string]$v
                        }
                    }
                }
                'description' = @{
                    Name='description'; Editable=$true; Sensitive=$false; Hint='description'; DefaultWidth=35; MinWidth=15
                    DisplayFormat = { param($v) if ($null -ne $v) { [string]$v } else { '' } }
                }
            }
        }
        default {
            return @{}
        }
    }
}

function Get-PmcFieldSchema {
    param(
        [Parameter(Mandatory=$true)][string]$Domain,
        [Parameter(Mandatory=$true)][string]$Field
    )
    $all = Get-PmcFieldSchemasForDomain -Domain $Domain
    if ($all.ContainsKey($Field)) { return $all[$Field] }
    return $null
}

#Export-ModuleMember -Function Get-PmcFieldSchemasForDomain, Get-PmcFieldSchema


# END FILE: ./module/Pmc.Strict/src/FieldSchemas.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/Focus.ps1
# SIZE: 8.2 KB
# MODIFIED: 2025-09-23 21:13:04
# ================================================================================

# Focus/Context System Implementation
# Based on t2.ps1 focus functionality

# State-only: no global context initialization

function Set-PmcFocus {
    param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category "Focus" -Message "Starting focus set" -Data @{ FreeText = $Context.FreeText }

    $data = Get-PmcDataAlias
    $focusText = ($Context.FreeText -join ' ').Trim()

    if ([string]::IsNullOrWhiteSpace($focusText)) {
        Write-PmcStyled -Style 'Warning' -Text "Usage: focus set <project-name>"
        return
    }

    # Find matching project
    $project = $data.projects | Where-Object { $_.name -and ($_.name.ToLower() -eq $focusText.ToLower()) } | Select-Object -First 1

    if (-not $project) {
        Write-PmcStyled -Style 'Warning' -Text ("Project '{0}' not found. Creating new project context." -f $focusText)
        # Auto-create project if it doesn't exist
        $project = [pscustomobject]@{
            name = $focusText
            description = "Auto-created via focus $(Get-Date -Format yyyy-MM-dd)"
            created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        }
        $data.projects += $project
    }

    # Persist context in data
    if (-not $data.PSObject.Properties['currentContext']) {
        $data | Add-Member -NotePropertyName currentContext -NotePropertyValue $project.name -Force
    } else {
        $data.currentContext = $project.name
    }

    # Mirror to centralized state
    Set-PmcState -Section 'Focus' -Key 'Current' -Value $project.name

    Save-StrictData $data 'focus set'

    Write-PmcStyled -Style 'Success' -Text ("🎯 Focus set to: '{0}'" -f $project.name)

    # Show context summary
    $contextTasks = @($data.tasks | Where-Object {
        $_ -ne $null -and (Pmc-HasProp $_ 'project') -and $_.project -eq $project.name -and (Pmc-HasProp $_ 'status') -and $_.status -eq 'pending'
    })

    Write-PmcStyled -Style 'Info' -Text ("   Pending tasks: {0}" -f $contextTasks.Count)

    if ($contextTasks.Count -gt 0) {
        $overdue = @($contextTasks | Where-Object { (Pmc-HasProp $_ 'due') -and $_.due -and ([datetime]$_.due) -lt (Get-Date).Date })
        $today = @($contextTasks | Where-Object { (Pmc-HasProp $_ 'due') -and $_.due -and ([datetime]$_.due) -eq (Get-Date).Date })

        if ($overdue.Count -gt 0) { Write-PmcStyled -Style 'Error' -Text ("   ⚠️  Overdue: {0}" -f $overdue.Count) }
        if ($today.Count -gt 0)   { Write-PmcStyled -Style 'Warning' -Text ("   📅 Due today: {0}" -f $today.Count) }
    }

    Write-PmcDebug -Level 2 -Category "Focus" -Message "Focus set successfully" -Data @{ Project = $project.name; PendingTasks = $contextTasks.Count }
}

function Clear-PmcFocus {
    param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category "Focus" -Message "Starting focus clear"

    $data = Get-PmcDataAlias

    # Clear persisted context
    if ($data.PSObject.Properties['currentContext']) {
        $data.currentContext = 'inbox'
    }

    # Mirror to centralized state
    Set-PmcState -Section 'Focus' -Key 'Current' -Value 'inbox'

    Save-StrictData $data 'focus clear'

    Write-PmcStyled -Style 'Success' -Text "🎯 Project focus cleared. Back to inbox."

    Write-PmcDebug -Level 2 -Category "Focus" -Message "Focus cleared successfully"
}

function Get-PmcFocusStatus {
    param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category "Focus" -Message "Starting focus status"

    $data = Get-PmcDataAlias

    Write-PmcStyled -Style 'Info' -Text "`nℹ️  CURRENT CONTEXT"
    Write-PmcStyled -Style 'Border' -Text "─────────────────────"

    # Resolve context via helper (handles uninitialized global state)
    $currentContext = Get-PmcCurrentContext

    if (-not $currentContext -or $currentContext -eq 'inbox') {
        Write-PmcStyled -Style 'Muted' -Text "  No active focus (inbox mode)"

        # Show inbox summary
    $inboxTasks = @($data.tasks | Where-Object {
            $_ -ne $null -and ((-not (Pmc-HasProp $_ 'project')) -or $_.project -eq 'inbox') -and (Pmc-HasProp $_ 'status') -and $_.status -eq 'pending'
        })
        Write-PmcStyled -Style 'Body' -Text ("  Inbox tasks: {0}" -f $inboxTasks.Count)
        return
    }

    Write-PmcStyled -Style 'Warning' -Text ("  Active Focus: {0}" -f $currentContext)

    # Find the project
    $project = $data.projects | Where-Object { $_.name -eq $currentContext } | Select-Object -First 1

    if ($project) {
        $desc = if ((Pmc-HasProp $project 'description') -and $project.description) { [string]$project.description } else { 'None' }
        Write-PmcStyled -Style 'Muted' -Text ("  Description: {0}" -f $desc)
    }

    # Show context statistics
    $contextTasks = @($data.tasks | Where-Object { (Pmc-HasProp $_ 'project') -and $_.project -eq $currentContext -and (Pmc-HasProp $_ 'status') -and $_.status -eq 'pending' })

    Write-PmcStyled -Style 'Body' -Text ("  Pending Tasks: {0}" -f $contextTasks.Count)

    if ($contextTasks.Count -gt 0) {
        $overdue = @($contextTasks | Where-Object { (Pmc-HasProp $_ 'due') -and $_.due -and [datetime]$_.due -lt (Get-Date).Date })
        $today = @($contextTasks | Where-Object { (Pmc-HasProp $_ 'due') -and $_.due -and ([datetime]$_.due) -eq (Get-Date).Date })
        $upcoming = @($contextTasks | Where-Object { (Pmc-HasProp $_ 'due') -and $_.due -and ([datetime]$_.due) -gt (Get-Date).Date -and ([datetime]$_.due) -le (Get-Date).Date.AddDays(7) })
        $nodue = @($contextTasks | Where-Object { -not (Pmc-HasProp $_ 'due') -or -not $_.due })

        Write-PmcStyled -Style 'Info' -Text "`n  Task Breakdown:"
        if ($overdue.Count -gt 0)  { Write-PmcStyled -Style 'Error'   -Text ("    ⚠️  Overdue: {0}" -f $overdue.Count) }
        if ($today.Count -gt 0)    { Write-PmcStyled -Style 'Warning' -Text ("    📅 Due today: {0}" -f $today.Count) }
        if ($upcoming.Count -gt 0) { Write-PmcStyled -Style 'Success' -Text ("    📋 Upcoming (7d): {0}" -f $upcoming.Count) }
        if ($nodue.Count -gt 0)    { Write-PmcStyled -Style 'Muted'   -Text ("    📝 No due date: {0}" -f $nodue.Count) }

        # Show blocked tasks in context
        $blocked = @($contextTasks | Where-Object { (Pmc-HasProp $_ 'blocked') -and $_.blocked })
        if ($blocked.Count -gt 0) { Write-PmcStyled -Style 'Error' -Text ("    🔒 Blocked: {0}" -f $blocked.Count) }

        # Show high priority tasks
        $highPriority = @($contextTasks | Where-Object { $_.priority -and $_.priority -le 2 })
        if ($highPriority.Count -gt 0) { Write-PmcStyled -Style 'Highlight' -Text ("    ⭐ High priority: {0}" -f $highPriority.Count) }
    }

    # Show recent activity in context
    $recentLogs = @($data.timelogs | Where-Object {
        $_.project -eq $currentContext -and
        [datetime]$_.date -ge (Get-Date).Date.AddDays(-7)
    })

    if ($recentLogs.Count -gt 0) {
        $totalMinutes = ($recentLogs | Measure-Object minutes -Sum).Sum
        $totalHours = [Math]::Round($totalMinutes / 60, 1)
        Write-PmcStyled -Style 'Info' -Text ("  Recent time (7d): {0} hours" -f $totalHours)
    }

    Write-PmcStyled -Style 'Muted' -Text ("`nTip: Use 'task list @{0}' to see all tasks in this context" -f $currentContext)

    Write-PmcDebug -Level 2 -Category "Focus" -Message "Focus status shown successfully" -Data @{ Context = $currentContext; TaskCount = $contextTasks.Count }
}

# Helper function to get current context
function Get-PmcCurrentContext {
    # State-only source of truth
    $cur = Get-PmcState -Section 'Focus' -Key 'Current'
    if ($null -eq $cur -or [string]::IsNullOrWhiteSpace([string]$cur)) { return 'inbox' }
    return $cur
}

# Helper function to filter tasks by current context
function Get-PmcContextTasks {
    param([switch]$PendingOnly)

    $data = Get-PmcDataAlias
    $context = Get-PmcCurrentContext

    $tasks = $data.tasks

    if ($context -ne 'inbox') {
        $tasks = $tasks | Where-Object { $_.project -eq $context }
    } else {
        $tasks = $tasks | Where-Object { -not $_.project -or $_.project -eq 'inbox' }
    }

    if ($PendingOnly) {
        $tasks = $tasks | Where-Object { $_.status -eq 'pending' }
    }

    return @($tasks)
}

Export-ModuleMember -Function Set-PmcFocus, Clear-PmcFocus, Get-PmcFocusStatus, Get-PmcCurrentContext, Get-PmcContextTasks


# END FILE: ./module/Pmc.Strict/src/Focus.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/Help.ps1
# SIZE: 20.26 KB
# MODIFIED: 2025-09-23 16:14:10
# ================================================================================

function Get-PmcSchema {
    param([string]$Domain,[string]$Action)
    $key = "$($Domain.ToLower()) $($Action.ToLower())"
    if ($Script:PmcParameterMap.ContainsKey($key)) { return $Script:PmcParameterMap[$key] }
    return @()
}

function Get-PmcHelp {
    param([PmcCommandContext]$Context)
    # Route to clean help system
    Show-PmcSmartHelp -Context $Context
}

# Static domain help (non-interactive)
function Show-PmcHelpDomain {
    param([PmcCommandContext]$Context)

    # Use AST parsing to better understand domain query
    $domain = $null

    if ($Context -and $Context.FreeText.Count -ge 1) {
        # Try AST parsing first
        try {
            $helpQuery = $Context.FreeText -join ' '
            if (Get-Command ConvertTo-PmcCommandAst -ErrorAction SilentlyContinue) {
                $ast = ConvertTo-PmcCommandAst -CommandText $helpQuery
                if ($ast.Domain) { $domain = $ast.Domain.ToLower() }
            }
        } catch {
            Write-PmcDebug -Level 2 -Category 'Help' -Message "AST parsing failed for domain help query"
        }

        # Fallback to simple token parsing
        if (-not $domain) { $domain = $Context.FreeText[0].ToLower() }
    }

    if (-not $domain) {
        Write-PmcStyled -Style 'Warning' -Text "Usage: help domain <domain> (e.g., help domain task)"
        return
    }
    if (-not $Script:PmcCommandMap.ContainsKey($domain)) { Write-PmcStyled -Style 'Error' -Text ("Unknown domain '{0}'" -f $domain); return }

    Write-PmcStyled -Style 'Title' -Text ("\nHELP — {0}" -f $domain.ToUpper())
    Write-PmcStyled -Style 'Border' -Text ("─" * 80)

    $rows = @()
    foreach ($a in ($Script:PmcCommandMap[$domain].Keys | Sort-Object)) {
        $key = "$domain $a"
        $desc = ''
        try { if ($Script:PmcCommandMeta.ContainsKey($key)) { $desc = [string]$Script:PmcCommandMeta[$key].Desc } } catch {}
        $rows += [pscustomobject]@{ Action=$a; Description=$desc }
    }
    foreach ($row in $rows) {
        $act = $row.Action.PadRight(18).Substring(0,18)
        $desc = if ($row.Description) { $row.Description } else { '' }
        Write-Host ("  {0} {1}" -f $act, $desc)
    }
}

# Static command help (arguments, usage)
function Show-PmcHelpCommand {
    param([PmcCommandContext]$Context)

    # Use AST parsing to better understand help command structure
    $domain = $null
    $action = $null

    if ($Context -and $Context.FreeText.Count -ge 1) {
        # Try AST parsing first for better command understanding
        try {
            $helpQuery = $Context.FreeText -join ' '
            if (Get-Command ConvertTo-PmcCommandAst -ErrorAction SilentlyContinue) {
                $ast = ConvertTo-PmcCommandAst -CommandText $helpQuery
                if ($ast.Domain) { $domain = $ast.Domain.ToLower() }
                if ($ast.Action) { $action = $ast.Action.ToLower() }
            }
        } catch {
            Write-PmcDebug -Level 2 -Category 'Help' -Message "AST parsing failed for help query, using fallback"
        }

        # Fallback to simple token parsing
        if (-not $domain -and $Context.FreeText.Count -ge 1) { $domain = $Context.FreeText[0].ToLower() }
        if (-not $action -and $Context.FreeText.Count -ge 2) { $action = $Context.FreeText[1].ToLower() }
    }

    if (-not $domain -or -not $action) {
        Write-PmcStyled -Style 'Warning' -Text "Usage: help command <domain> <action> (e.g., help command task add)"
        return
    }
    if (-not $Script:PmcCommandMap.ContainsKey($domain)) { Write-PmcStyled -Style 'Error' -Text ("Unknown domain '{0}'" -f $domain); return }
    if (-not $Script:PmcCommandMap[$domain].ContainsKey($action)) { Write-PmcStyled -Style 'Error' -Text ("Unknown action '{0}' for domain '{1}'" -f $action,$domain); return }

    $title = "HELP — {0} {1}" -f $domain.ToUpper(), $action
    Write-PmcStyled -Style 'Title' -Text ("\n{0}" -f $title)
    Write-PmcStyled -Style 'Border' -Text ("─" * 80)

    # Description (if available)
    $key = "$domain $action"
    $desc = ''
    try { if ($Script:PmcCommandMeta.ContainsKey($key)) { $desc = [string]$Script:PmcCommandMeta[$key].Desc } } catch {}
    if ($desc) { Write-PmcStyled -Style 'Info' -Text ("  {0}" -f $desc) }

    # Schema
    $schema = Get-PmcSchema -Domain $domain -Action $action
    if (-not $schema -or @($schema).Count -eq 0) { Write-PmcStyled -Style 'Muted' -Text '  (no arguments)'; return }

    Write-PmcStyled -Style 'Header' -Text "\n  Args:"
    foreach ($def in $schema) {
        $name = [string]$def['Name']
        $pref = if ($def['Prefix']) { [string]$def['Prefix'] } else { '' }
        $type = if ($def['Type']) { [string]$def['Type'] } else { 'Text' }
        $req  = if ($def['Required']) { 'required' } else { '' }
        $help = if ($def['Description']) { [string]$def['Description'] } else { '' }
        $left = (if ($pref) { "$pref$name" } else { $name }).PadRight(18).Substring(0,18)
        $right = ("[{0}] {1}" -f $type,$help)
        if ($req) { $right = "$right (required)" }
        Write-Host ("  {0} {1}" -f $left, $right)
    }

    # Usage hint
    $usage = "{0} {1}" -f $domain, $action
    foreach ($def in $schema) {
        $token = if ($def['Prefix']) { "" + [string]$def['Prefix'] + [string]$def['Name'] } elseif ($def['Name'] -match '^(?i)text$') { '<text>' } else { "<" + [string]$def['Name'] + ">" }
        if (-not $def['Required']) { $token = "[$token]" }
        $usage += " $token"
    }
    Write-PmcStyled -Style 'Border' -Text ("\n{0}" -f $usage)
}

# Dedicated query help (static)
function Show-PmcHelpQuery {
    param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Title' -Text "\nQUERY LANGUAGE"
    Write-PmcStyled -Style 'Border' -Text ("─" * 80)

    # Try to load reference doc and print key sections
    $root = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
    $ref = Join-Path $root 'PMC_QUERY_LANGUAGE_REFERENCE.md'
    if (-not (Test-Path $ref)) { Write-PmcStyled -Style 'Warning' -Text 'Reference file not found.'; return }
    $content = Get-Content $ref -Raw

    # Extract top sections by headings
    $sections = @()
    $pattern = "(?ms)^##\s+(.+?)\n(.*?)(?=\n##\s+|\Z)"
    $matches = [regex]::Matches($content, $pattern)
    foreach ($m in $matches) {
        $sections += @{ Title=$m.Groups[1].Value.Trim(); Body=$m.Groups[2].Value.Trim() }
    }

    $wanted = @('Overview','Core Syntax','Filters','Operators','Grouping & Sorting','Views','Examples')
    foreach ($w in $wanted) {
        $sec = $sections | Where-Object { $_.Title -like "$w*" } | Select-Object -First 1
        if ($sec) {
            Write-PmcStyled -Style 'Header' -Text ("\n  {0}" -f $sec.Title)
            $lines = ($sec.Body -split "`n") | Where-Object { $_.Trim() -ne '' } | Select-Object -First 12
            foreach ($ln in $lines) { Write-Host ("    {0}" -f $ln.TrimEnd()) }
        }
    }
    Write-PmcStyled -Style 'Muted' -Text ("\nSee: {0}" -f $ref)
    Write-PmcStyled -Style 'Info' -Text "\nRelated help:"
    Write-Host "  help guide query      — Guided tour of filters and views"
    Write-Host "  help examples query   — Practical, copyable query examples"
}

# Search across commands and help content
function Show-PmcHelpSearch {
    param([PmcCommandContext]$Context)

    # Use AST parsing to better understand search query
    $q = ''
    if ($Context -and $Context.FreeText -and $Context.FreeText.Count -gt 0) {
        # Try AST parsing first for complex queries
        try {
            $searchQuery = $Context.FreeText -join ' '
            if (Get-Command ConvertTo-PmcCommandAst -ErrorAction SilentlyContinue) {
                $ast = ConvertTo-PmcCommandAst -CommandText $searchQuery
                # For search, we want the full free text, not just structured parts
                $q = $searchQuery
            } else {
                $q = $searchQuery
            }
        } catch {
            $q = ($Context.FreeText[0] + '')
        }
    }

    $q = $q.Trim()
    if (-not $q) {
        Write-PmcStyled -Style 'Warning' -Text "Usage: help search <text> (e.g., help search 'task add')"
        return
    }

    $rows = @()
    # Search domain/actions with descriptions
    foreach ($domain in ($Script:PmcCommandMap.Keys)) {
        foreach ($action in ($Script:PmcCommandMap[$domain].Keys)) {
            $cmd = ("{0} {1}" -f $domain, $action)
            $desc = ''
            try { if ($Script:PmcCommandMeta.ContainsKey($cmd)) { $desc = [string]$Script:PmcCommandMeta[$cmd].Desc } } catch {}
            $rows += [pscustomobject]@{ Type='Command'; Text=$cmd; Description=$desc; Source=$domain }
        }
    }
    # Search curated help content
    try {
        if ($Script:PmcHelpContent) {
            foreach ($kv in $Script:PmcHelpContent.GetEnumerator()) {
                $cat = [string]$kv.Key
                foreach ($it in $kv.Value.Items) {
                    $text = if ($it.PSObject.Properties['Command']) { [string]$it.Command } elseif ($it.PSObject.Properties['Item']) { [string]$it.Item } else { '' }
                    $desc = if ($it.PSObject.Properties['Description']) { [string]$it.Description } else { '' }
                    if ($text -or $desc) { $rows += [pscustomobject]@{ Type='Guide'; Text=$text; Description=$desc; Source=$cat } }
                }
            }
        }
    } catch {}

    # Parse quoted phrases and remaining terms
    $phraseRegex = '"([^"]+)"'
    $phrases = @()
    $m = [regex]::Matches($q, $phraseRegex)
    foreach ($mm in $m) { $phrases += ($mm.Groups[1].Value + '').ToLowerInvariant() }
    $rest = ([regex]::Replace($q, $phraseRegex, ' ')).Trim()
    $terms = @()
    foreach ($t in ($rest -split '\s+')) { if (-not [string]::IsNullOrWhiteSpace($t)) { $terms += $t.ToLowerInvariant() } }
    if ($phrases.Count -eq 0 -and $terms.Count -eq 0) { $terms = @($q.ToLowerInvariant()) }

    $normalizedQuery = $q.ToLowerInvariant()

    # Scoring:
    # - Exact full command match: +10 (commands only)
    # - Phrase match in Text: +6 if startswith; +5 if contains; +4 if in Description
    # - Term match: Text startswith +3; word-boundary +3; contains +2; Description/Source +1
    # - Commands get +1 baseline
    $scored = @()
    foreach ($row in $rows) {
        if ($null -eq $row) { continue }
        $text = ([string]$row.Text)
        $desc = ([string]$row.Description)
        $src  = ([string]$row.Source)
        $lt = $text.ToLowerInvariant()
        $ld = $desc.ToLowerInvariant()
        $ls = $src.ToLowerInvariant()
        $score = 0
        $ok = $true

        # Require each phrase to appear somewhere
        foreach ($p in $phrases) {
            $phraseHit = $false
            if ($lt.StartsWith($p)) { $score += 6; $phraseHit = $true }
            elseif ($lt.Contains($p)) { $score += 5; $phraseHit = $true }
            elseif ($ld.Contains($p)) { $score += 4; $phraseHit = $true }
            elseif ($ls.Contains($p)) { $score += 3; $phraseHit = $true }
            if (-not $phraseHit) { $ok = $false; break }
        }
        if (-not $ok) { continue }

        # Terms (AND logic)
        foreach ($term in $terms) {
            $termScore = 0
            if ($lt -eq $term) { $termScore = [Math]::Max($termScore, 4) }
            if ($lt.StartsWith($term)) { $termScore = [Math]::Max($termScore, 3) }
            $wb = "\\b" + [regex]::Escape($term) + "\\b"
            if ([regex]::IsMatch($lt, $wb)) { $termScore = [Math]::Max($termScore, 3) }
            if ($lt.Contains($term)) { $termScore = [Math]::Max($termScore, 2) }
            if ($ld.Contains($term)) { $termScore = [Math]::Max($termScore, 1) }
            if ($ls.Contains($term)) { $termScore = [Math]::Max($termScore, 1) }
            if ($termScore -eq 0) { $ok = $false; break }
            $score += $termScore
        }
        if (-not $ok) { continue }

        # Bonuses
        if ($row.Type -eq 'Command') {
            $score += 1
            if ($lt -eq $normalizedQuery) { $score += 10 }
            elseif ($phrases.Count -eq 1 -and $lt -eq $phrases[0]) { $score += 8 }
        }

        $scored += [pscustomobject]@{ Score=$score; Type=$row.Type; Text=$text; Description=$desc; Source=$src }
    }

    $matches = @($scored | Sort-Object -Property @{Expression='Score';Descending=$true}, @{Expression='Type';Descending=$false}, @{Expression='Text';Descending=$false})

    if ($matches.Count -eq 0) {
        Write-PmcStyled -Style 'Muted' -Text ("No help results for: '{0}'" -f $q)
        return
    }

    $cols = @{
        Type=@{ Header='Type'; Width=8; Alignment='Left' }
        Text=@{ Header='Text'; Width=32; Alignment='Left' }
        Description=@{ Header='Description'; Width=0; Alignment='Left' }
        Source=@{ Header='Source'; Width=14; Alignment='Left' }
    }

    Show-PmcDataGrid -Domains @('help-search') -Columns $cols -Data $matches -Title ("Help Search — {0}" -f $q) -Interactive -OnSelectCallback {
        param($item)
        try { if ($item -and $item.PSObject.Properties['Text'] -and $item.Text) { Pmc-InsertAtCursor (([string]$item.Text) + ' ') } } catch {}
    }
}

# Interactive examples for common tasks and query/kanban
function Show-PmcHelpExamples {
    param([PmcCommandContext]$Context)
    $topic = if ($Context -and $Context.FreeText.Count -gt 0) { ($Context.FreeText[0] + '').ToLower() } else { '' }

    switch ($topic) {
        'query' {
            $rows = @(
                [pscustomobject]@{ Category='🎯 PRIORITY'; Command='q tasks p1'; Description='Only high priority tasks' }
                [pscustomobject]@{ Category='🎯 PRIORITY'; Command='q tasks p<=2'; Description='High and medium priority' }
                [pscustomobject]@{ Category='📅 DATE'; Command='q tasks due:today'; Description='Due today' }
                [pscustomobject]@{ Category='📅 DATE'; Command='q tasks overdue'; Description='Past due' }
                [pscustomobject]@{ Category='🏷️ PROJECT'; Command='q tasks @work'; Description='Project filter' }
                [pscustomobject]@{ Category='🏷️ TAG'; Command='q tasks #urgent'; Description='Tagged urgent' }
                [pscustomobject]@{ Category='📊 VIEW'; Command='q tasks group:status'; Description='Kanban by status' }
                [pscustomobject]@{ Category='⚡ COMBO'; Command='q tasks p<=2 @work due>=today'; Description='Combined filters' }
            )

            $cols = @{
                Category=@{ Header='Category'; Width=14; Alignment='Left' }
                Command=@{ Header='Command'; Width=28; Alignment='Left' }
                Description=@{ Header='Description'; Width=0; Alignment='Left' }
            }
            Show-PmcDataGrid -Domains @('help-examples') -Columns $cols -Data $rows -Title 'Query Language Examples' -Interactive
            return
        }
        'kanban' {
            $rows = @(
                [pscustomobject]@{ Category='🎯 ACCESS'; Command='q tasks group:status'; Description='Auto-kanban by status' }
                [pscustomobject]@{ Category='🎯 ACCESS'; Command='q tasks view:kanban'; Description='Force kanban view' }
                [pscustomobject]@{ Category='🎮 KEYS'; Command='←/→'; Description='Move between lanes' }
                [pscustomobject]@{ Category='🎮 KEYS'; Command='↑/↓'; Description='Move between cards' }
                [pscustomobject]@{ Category='🎮 KEYS'; Command='Space'; Description='Start/complete move' }
                [pscustomobject]@{ Category='🎮 KEYS'; Command='Enter'; Description='Open details/editor' }
                [pscustomobject]@{ Category='🎮 KEYS'; Command='Esc'; Description='Exit or cancel' }
            )
            $cols = @{
                Category=@{ Header='Category'; Width=14; Alignment='Left' }
                Command=@{ Header='Command/Key'; Width=20; Alignment='Left' }
                Description=@{ Header='Description'; Width=0; Alignment='Left' }
            }
            Show-PmcDataGrid -Domains @('help-examples') -Columns $cols -Data $rows -Title 'Kanban Workflow Examples' -Interactive
            return
        }
        default {
            $rows = @(
                [pscustomobject]@{ Category='🚀 QUICK START'; Command='today'; Description='Tasks due today' }
                [pscustomobject]@{ Category='🚀 QUICK START'; Command='add "New task" @work p1 due:today'; Description='Add new task' }
                [pscustomobject]@{ Category='🔎 QUERY'; Command='help examples query'; Description='See query examples' }
                [pscustomobject]@{ Category='📋 KANBAN'; Command='help examples kanban'; Description='See kanban examples' }
            )
            $cols = @{
                Category=@{ Header='Category'; Width=16; Alignment='Left' }
                Command=@{ Header='Command'; Width=32; Alignment='Left' }
                Description=@{ Header='Description'; Width=0; Alignment='Left' }
            }
            Show-PmcDataGrid -Domains @('help-examples') -Columns $cols -Data $rows -Title 'PMC Examples — Quick Start' -Interactive
        }
    }
}

# Focused guides for important features
function Show-PmcHelpGuide {
    param([PmcCommandContext]$Context)
    $topic = if ($Context -and $Context.FreeText.Count -gt 0) { ($Context.FreeText[0] + '').ToLower() } else { '' }

    switch ($topic) {
        'query' {
            $rows = @(
                [pscustomobject]@{ Section='🚀 BASICS'; Item='q tasks'; Description='Show all tasks' }
                [pscustomobject]@{ Section='🎯 PRIORITY'; Item='q tasks p1'; Description='High priority' }
                [pscustomobject]@{ Section='📅 DATES'; Item='q tasks due:today'; Description='Due today' }
                [pscustomobject]@{ Section='🏷️ PROJECT'; Item='q tasks @work'; Description='Project filter' }
                [pscustomobject]@{ Section='📊 DISPLAY'; Item='q tasks cols:id,text,due'; Description='Choose columns' }
                [pscustomobject]@{ Section='📊 VIEWS'; Item='q tasks group:status'; Description='Kanban by status' }
                [pscustomobject]@{ Section='🔗 COMBINE'; Item='q tasks p<=2 @work due>today'; Description='Multiple filters' }
                [pscustomobject]@{ Section='💡 TIPS'; Item='Tab completion'; Description='Complete filters and values' }
            )
            $cols = @{
                Section=@{ Header='Category'; Width=14; Alignment='Left' }
                Item=@{ Header='Filter/Command'; Width=28; Alignment='Left' }
                Description=@{ Header='Description'; Width=0; Alignment='Left' }
            }
            Show-PmcDataGrid -Domains @('help-guide') -Columns $cols -Data $rows -Title 'Query Language Guide' -Interactive
            return
        }
        'kanban' {
            $rows = @(
                [pscustomobject]@{ Category='🎯 ACCESS'; Item='q tasks group:status'; Description='Auto-enable kanban' }
                [pscustomobject]@{ Category='🎮 NAV'; Item='←/→, ↑/↓'; Description='Move lanes/cards' }
                [pscustomobject]@{ Category='🎮 NAV'; Item='Space'; Description='Start/complete move' }
                [pscustomobject]@{ Category='🎮 NAV'; Item='Enter'; Description='Open/edit task' }
                [pscustomobject]@{ Category='🎮 NAV'; Item='Esc'; Description='Exit/cancel' }
                [pscustomobject]@{ Category='🎨 VISUAL'; Item='🔴🟡🟢'; Description='Priority indicators' }
                [pscustomobject]@{ Category='🎨 VISUAL'; Item='⚠️📅'; Description='Due indicators' }
            )
            $cols = @{
                Category=@{ Header='Category'; Width=14; Alignment='Left' }
                Item=@{ Header='Command/Key'; Width=22; Alignment='Left' }
                Description=@{ Header='Description'; Width=0; Alignment='Left' }
            }
            Show-PmcDataGrid -Domains @('help-guide') -Columns $cols -Data $rows -Title 'Kanban View Guide' -Interactive
            return
        }
        default {
            $rows = @(
                [pscustomobject]@{ Topic='help guide query'; Description='Query language & filtering guide' }
                [pscustomobject]@{ Topic='help guide kanban'; Description='Kanban navigation and usage' }
                [pscustomobject]@{ Topic='help examples'; Description='Practical, copyable examples' }
            )
            $cols = @{
                Topic=@{ Header='Command'; Width=26; Alignment='Left' }
                Description=@{ Header='Description'; Width=0; Alignment='Left' }
            }
            Show-PmcDataGrid -Domains @('help-guide') -Columns $cols -Data $rows -Title 'PMC Help Guide — Topics' -Interactive
        }
    }
}


# END FILE: ./module/Pmc.Strict/src/Help.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/HelpUI.ps1
# SIZE: 9.78 KB
# MODIFIED: 2025-09-23 20:29:35
# ================================================================================

function Show-PmcHelpCategories {
    param($Context)

    Write-PmcDebug -Level 1 -Category 'HELP' -Message 'Show-PmcHelpCategories START'

    # Build help categories data
    $rows = @()
    $useCurated = ($Script:PmcHelpContent -and $Script:PmcHelpContent.Count -gt 0)
    if ($useCurated) {
        foreach ($entry in $Script:PmcHelpContent.GetEnumerator()) {
            $rows += [pscustomobject]@{
                category = [string]$entry.Key
                items = @($entry.Value.Items).Count
                description = [string]$entry.Value.Description
            }
        }
    } else {
        # Fallback to domain listing from CommandMap
        foreach ($domain in ($Script:PmcCommandMap.Keys | Sort-Object)) {
            $actions = 0
            try { $actions = @($Script:PmcCommandMap[$domain].Keys).Count } catch { $actions = 0 }
            $desc = switch ($domain) {
                'task' { 'Task management commands' }
                'project' { 'Project management commands' }
                'time' { 'Time tracking commands' }
                'view' { 'Data viewing commands' }
                'help' { 'Help system commands' }
                'config' { 'Configuration commands' }
                default { 'Domain commands' }
            }
            $rows += [pscustomobject]@{
                category = $domain
                items = $actions
                description = $desc
            }
        }
    }

    # Use template display system
    $helpTemplate = [PmcTemplate]::new('help-categories', @{
        type = 'grid'
        header = 'Category          Items  Description'
        row = '{category,-16} {items,6}  {description}'
        settings = @{ separator = '─'; minWidth = 60 }
    })

    Write-PmcStyled -Style 'Header' -Text "`n📚 PMC HELP — CATEGORIES`n"
    Render-GridTemplate -Data $rows -Template $helpTemplate
    Write-PmcStyled -Style 'Info' -Text "`nUse: help domain <category> (e.g., 'help domain task')"
}

function Show-PmcHelpCommands {
    param($Context,[string]$Domain)

    Write-PmcDebug -Level 1 -Category 'HELP' -Message 'Show-PmcHelpCommands START' -Data @{ Domain = $Domain }

    if ([string]::IsNullOrWhiteSpace($Domain)) { return }

    # Build rows from domain actions
    $rows = @()
    $map = $null
    try { $map = $Script:PmcCommandMap[$Domain] } catch { $map = $null }

    if ($map) {
        foreach ($action in ($map.Keys | Sort-Object)) {
            $full = "{0} {1}" -f $Domain, $action
            $desc = ''
            try {
                if ($Script:PmcCommandMeta.ContainsKey($full)) {
                    $desc = [string]$Script:PmcCommandMeta[$full].Desc
                }
            } catch {}
            $rows += [pscustomobject]@{
                command = $action
                full = $full
                description = $desc
            }
        }
    } else {
        Write-PmcStyled -Style 'Error' -Text "Domain '$Domain' not found."
        return
    }

    # Use template display system
    $helpTemplate = [PmcTemplate]::new('help-commands', @{
        type = 'grid'
        header = 'Command           Description'
        row = '{command,-18} {description}'
        settings = @{ separator = '─'; minWidth = 50 }
    })

    Write-PmcStyled -Style 'Header' -Text "`n📚 PMC HELP — $($Domain.ToUpper())`n"
    Render-GridTemplate -Data $rows -Template $helpTemplate
    Write-PmcStyled -Style 'Info' -Text "`nUse: help command <domain> <action> (e.g., 'help command task add')"
}

# Show help topic content using template display
function Show-PmcHelpTopic {
    param($Context,[string]$Topic)
    Write-PmcDebug -Level 1 -Category 'HELP' -Message 'Show-PmcHelpTopic START' -Data @{ Topic=$Topic }

    Write-PmcStyled -Style 'Header' -Text "`n📚 HELP — $($Topic.ToUpper())`n"

    $topicLC = ($Topic + '').ToLower().Trim()
    switch ($topicLC) {
        'query' {
            Write-PmcStyled -Style 'Subheader' -Text 'PMC Query Language'
            Write-PmcStyled -Style 'Info' -Text 'Basic query syntax:'
            Write-PmcStyled -Style 'Code' -Text '  task list status:pending'
            Write-PmcStyled -Style 'Code' -Text '  task list due:today'
            Write-PmcStyled -Style 'Code' -Text '  task list project:work'
            Write-PmcStyled -Style 'Info' -Text '`nOperators: =, !=, <, >, contains, startswith, endswith'
            Write-PmcStyled -Style 'Info' -Text 'Logical: and, or, not'
        }
        'examples' {
            Write-PmcStyled -Style 'Subheader' -Text 'Common PMC Examples'
            Write-PmcStyled -Style 'Info' -Text 'Add a task:'
            Write-PmcStyled -Style 'Code' -Text '  task add "Fix login bug" project:web due:2024-01-15'
            Write-PmcStyled -Style 'Info' -Text '`nList overdue tasks:'
            Write-PmcStyled -Style 'Code' -Text '  view overdue'
            Write-PmcStyled -Style 'Info' -Text '`nStart time tracking:'
            Write-PmcStyled -Style 'Code' -Text '  timer start'
        }
        default {
            Write-PmcStyled -Style 'Warning' -Text "No detailed help available for topic: $Topic"
        }
    }
}

function Show-PmcSmartHelp {
    param($Context)
    # Show main help categories with template display
    Show-PmcHelpCategories -Context $Context
}

# Show help for a specific domain (static display)
function Show-PmcHelpDomain {
    param($Context, [string]$Domain)
    if ($Context.Args.ContainsKey('domain')) {
        $Domain = $Context.Args['domain']
    }
    if ([string]::IsNullOrWhiteSpace($Domain)) {
        Write-PmcStyled -Style 'Warning' -Text 'Usage: help domain <domain_name>'
        return
    }
    Show-PmcHelpCommands -Context $Context -Domain $Domain
}

# Show help for a specific command (static display)
function Show-PmcHelpCommand {
    param($Context, [string]$Command)
    if ($Context.Args.ContainsKey('command')) {
        $Command = $Context.Args['command']
    }
    if ([string]::IsNullOrWhiteSpace($Command)) {
        Write-PmcStyled -Style 'Warning' -Text 'Usage: help command <command_name>'
        return
    }

    Write-PmcStyled -Style 'Header' -Text "`n📚 COMMAND HELP: $($Command.ToUpper())"

    # Try to find command info
    $found = $false
    foreach ($domain in $Script:PmcCommandMap.Keys) {
        foreach ($action in $Script:PmcCommandMap[$domain].Keys) {
            $fullCmd = "$domain $action"
            if ($fullCmd -eq $Command) {
                $func = $Script:PmcCommandMap[$domain][$action]
                $desc = if ($Script:PmcCommandMeta.ContainsKey($fullCmd)) { $Script:PmcCommandMeta[$fullCmd].Desc } else { 'No description available' }

                Write-PmcStyled -Style 'Info' -Text "`nCommand: $fullCmd"
                Write-PmcStyled -Style 'Info' -Text "Function: $func"
                Write-PmcStyled -Style 'Info' -Text "Description: $desc"
                $found = $true
                break
            }
        }
        if ($found) { break }
    }

    if (-not $found) {
        Write-PmcStyled -Style 'Warning' -Text "Command '$Command' not found."
    }
}

# Show query language help
function Show-PmcHelpQuery {
    param($Context)
    Show-PmcHelpTopic -Context $Context -Topic 'query'
}

# Show help examples
function Show-PmcHelpExamples {
    param($Context)
    Show-PmcHelpTopic -Context $Context -Topic 'examples'
}

# Show interactive help guide
function Show-PmcHelpGuide {
    param($Context)
    Write-PmcStyled -Style 'Header' -Text "`n📚 PMC HELP GUIDE`n"
    Write-PmcStyled -Style 'Subheader' -Text 'Getting Started:'
    Write-PmcStyled -Style 'Info' -Text '• help show - Browse all help categories'
    Write-PmcStyled -Style 'Info' -Text '• help domain <name> - Show commands for a domain'
    Write-PmcStyled -Style 'Info' -Text '• help command <cmd> - Show detailed command help'
    Write-PmcStyled -Style 'Info' -Text '• help query - Learn the query language'
    Write-PmcStyled -Style 'Info' -Text '• help examples - See practical examples'
    Write-PmcStyled -Style 'Subheader' -Text '`nQuick Start:'
    Write-PmcStyled -Style 'Code' -Text '  task add "My first task"'
    Write-PmcStyled -Style 'Code' -Text '  task list'
    Write-PmcStyled -Style 'Code' -Text '  view today'
}

# Search help content and commands
function Show-PmcHelpSearch {
    param($Context, [string]$Query)
    if ($Context.Args.ContainsKey('query')) {
        $Query = $Context.Args['query']
    }
    if ([string]::IsNullOrWhiteSpace($Query)) {
        Write-PmcStyled -Style 'Warning' -Text 'Usage: help search <search_term>'
        return
    }

    Write-PmcStyled -Style 'Header' -Text "`n🔍 HELP SEARCH: $Query`n"

    $results = @()
    $queryLower = $Query.ToLower()

    # Search command descriptions
    foreach ($domain in $Script:PmcCommandMap.Keys) {
        foreach ($action in $Script:PmcCommandMap[$domain].Keys) {
            $fullCmd = "$domain $action"
            $desc = if ($Script:PmcCommandMeta.ContainsKey($fullCmd)) { $Script:PmcCommandMeta[$fullCmd].Desc } else { '' }

            if ($fullCmd.ToLower().Contains($queryLower) -or $desc.ToLower().Contains($queryLower)) {
                $results += [pscustomobject]@{
                    command = $fullCmd
                    description = $desc
                }
            }
        }
    }

    if ($results.Count -gt 0) {
        $searchTemplate = [PmcTemplate]::new('help-search', @{
            type = 'grid'
            header = 'Command              Description'
            row = '{command,-20} {description}'
            settings = @{ separator = '─'; minWidth = 50 }
        })
        Render-GridTemplate -Data $results -Template $searchTemplate
    } else {
        Write-PmcStyled -Style 'Warning' -Text "No help results found for: $Query"
    }
}

Export-ModuleMember -Function Show-PmcSmartHelp, Show-PmcHelpCategories, Show-PmcHelpCommands, Show-PmcHelpDomain, Show-PmcHelpCommand, Show-PmcHelpQuery, Show-PmcHelpExamples, Show-PmcHelpGuide, Show-PmcHelpSearch


# END FILE: ./module/Pmc.Strict/src/HelpUI.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/ImportExport.ps1
# SIZE: 5.4 KB
# MODIFIED: 2025-09-24 05:34:23
# ================================================================================

# Generic import/export of tasks (CSV/JSON)

function Export-PmcTasks {
    param(
        $Context,
        [string]$Path
    )

    # Handle both Context and direct -Path parameter calls
    $outCsv = $null; $outJson = $null

    if ($Path) {
        # Direct path parameter provided
        if ($Path -match '\.json$') { $outJson = $Path }
        else { $outCsv = $Path }
    } elseif ($Context) {
        # Parse tokens from context like out:foo.csv json:bar.json
        foreach ($t in $Context.FreeText) {
            if ($t -match '^(?i)out:(.+)$') { $outCsv = $matches[1] }
            elseif ($t -match '^(?i)csv:(.+)$') { $outCsv = $matches[1] }
            elseif ($t -match '^(?i)json:(.+)$') { $outJson = $matches[1] }
        }
        if (-not $outCsv -and -not $outJson) { $outCsv = 'exports/tasks.csv' }
    } else {
        $outCsv = 'exports/tasks.csv'
    }

    $data = Get-PmcDataAlias

    $tasks = @($data.tasks)
    if ($outCsv) {
        try {
            $path = Get-PmcSafePath $outCsv
            if (-not (Test-Path (Split-Path $path -Parent))) { New-Item -ItemType Directory -Path (Split-Path $path -Parent) -Force | Out-Null }
            $rows = @()
            foreach ($t in $tasks) {
                $rows += [pscustomobject]@{
                    ID = $t.id
                    Text = $t.text
                    Project = (if ($t.project) { $t.project } else { 'inbox' })
                    Priority = (if ($t.priority) { $t.priority } else { 0 })
                    Due = (if ($t.due) { $t.due } else { '' })
                    Status = (if ($t.status) { $t.status } else { 'pending' })
                    Created = (if ($t.created) { $t.created } else { '' })
                }
            }
            $rows | Export-Csv -Path $path -NoTypeInformation -Encoding UTF8
            Show-PmcSuccess ("Exported CSV: {0}" -f $path)
        } catch { Show-PmcError ("CSV export failed: {0}" -f $_) }
    }
    if ($outJson) {
        try {
            $path = Get-PmcSafePath $outJson
            if (-not (Test-Path (Split-Path $path -Parent))) { New-Item -ItemType Directory -Path (Split-Path $path -Parent) -Force | Out-Null }
            $tasks | ConvertTo-Json -Depth 8 | Set-Content -Path $path -Encoding UTF8
            Show-PmcSuccess ("Exported JSON: {0}" -f $path)
        } catch { Show-PmcError ("JSON export failed: {0}" -f $_) }
    }
}

function Import-PmcTasks {
    param([PmcCommandContext]$Context)
    $pathArg = ($Context.FreeText -join ' ').Trim()
    if ([string]::IsNullOrWhiteSpace($pathArg)) { Write-PmcStyled -Style 'Warning' -Text "Usage: import tasks <path.csv|path.json>"; return }
    $path = Get-PmcSafePath $pathArg
    if (-not (Test-Path $path)) { Show-PmcError ("File not found: {0}" -f $path); return }
    $data = Get-PmcDataAlias
    $added = 0
    if ($path -match '\.json$') {
        try { $items = Get-Content $path -Raw | ConvertFrom-Json } catch { Show-PmcError "Invalid JSON"; return }
        foreach ($r in $items) {
            $text = if ($r.PSObject.Properties['text'] -and $r.text) { $r.text } elseif ($r.PSObject.Properties['Text'] -and $r.Text) { $r.Text } else { $null }
            if (-not $text) { continue }
            $id = Get-PmcNextTaskId $data
            $projVal = if ($r.PSObject.Properties['project'] -and $r.project) { $r.project } elseif ($r.PSObject.Properties['Project'] -and $r.Project) { $r.Project } else { 'inbox' }
            $priVal = if ($r.PSObject.Properties['priority'] -and $r.priority) { $r.priority } elseif ($r.PSObject.Properties['Priority'] -and $r.Priority) { $r.Priority } else { 0 }
            $t = @{ id=$id; text=$text; project=$projVal; priority=$priVal; status='pending'; created=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss') }
            if (($r.PSObject.Properties['due'] -and $r.due) -or ($r.PSObject.Properties['Due'] -and $r.Due)) { try { $t.due = ([datetime]((if ($r.due) { $r.due } else { $r.Due }))).ToString('yyyy-MM-dd') } catch {
                # Date parsing failed - skip due date assignment
            } }
            $data.tasks += $t; $added++
        }
        Save-StrictData $data 'import tasks'
        Show-PmcSuccess ("Imported {0} task(s) from JSON" -f $added)
        return
    }
    if ($path -match '\.csv$') {
        $rows = @(); try { $rows = Import-Csv -Path $path } catch { Show-PmcError ("Failed to read CSV: {0}" -f $_); return }
        foreach ($r in $rows) {
            $text = if ($r.PSObject.Properties['Text'] -and $r.Text) { $r.Text } elseif ($r.PSObject.Properties['Task'] -and $r.Task) { $r.Task } else { $null }
            if (-not $text) { continue }
            $proj = if ($r.PSObject.Properties['Project'] -and $r.Project) { $r.Project } else { 'inbox' }
            $pri = try { [int]$r.Priority } catch { 0 }
            $due = $null; try { if ($r.Due) { $due = [datetime]$r.Due } } catch {
                # Date parsing failed - due will remain null
            }
            $id = Get-PmcNextTaskId $data
            $task = @{ id=$id; text=$text; project=$proj; priority=$pri; status='pending'; created=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss') }
            if ($due) { $task.due = $due.ToString('yyyy-MM-dd') }
            $data.tasks += $task; $added++
        }
        Save-StrictData $data 'import tasks'
        Show-PmcSuccess ("Imported {0} task(s) from CSV" -f $added)
        return
    }
    Show-PmcWarning 'Unsupported file type (use .csv or .json)'
}

Export-ModuleMember -Function Export-PmcTasks, Import-PmcTasks


# END FILE: ./module/Pmc.Strict/src/ImportExport.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/InputEngine.ps1
# SIZE: 6.81 KB
# MODIFIED: 2025-09-23 16:55:24
# ================================================================================

# PSReadLine-only input engine for PMC
# No fallbacks - if PSReadLine doesn't work, we crash

Set-StrictMode -Version Latest

# Module-level state
$Script:PmcPSReadLineInitialized = $false

function Get-PmcCompletions {
    param(
        [string]$Buffer
    )

    $tokens = $Buffer.Trim() -split '\s+' | Where-Object { $_ }

    $commandMap = $Script:PmcCommandMap
    if (-not $commandMap) { return @() }

    $completions = @()

    if ($tokens.Count -eq 0) {
        $domains = @($commandMap.Keys) + @('help', 'exit', 'quit', 'status')
        $completions = $domains | Sort-Object
    }
    elseif ($tokens.Count -eq 1) {
        $domains = @($commandMap.Keys) + @('help', 'exit', 'quit', 'status')
        $filter = $tokens[0]
        $completions = $domains | Where-Object { $_ -like "$filter*" } | Sort-Object
    }
    elseif ($tokens.Count -eq 2) {
        $domain = $tokens[0]
        if ($commandMap.ContainsKey($domain)) {
            $actions = @($commandMap[$domain].Keys)
            $filter = $tokens[1]
            $completions = $actions | Where-Object { $_ -like "$filter*" } | Sort-Object
        }
    }

    return $completions
}

function Initialize-PmcPSReadLine {
    Write-PmcDebug -Level 1 -Category 'PSREADLINE' -Message "Starting PSReadLine initialization"

    # Import PSReadLine - crash if not available
    Import-Module PSReadLine -Force -ErrorAction Stop
    Write-PmcDebug -Level 1 -Category 'PSREADLINE' -Message "PSReadLine module imported"

    # Configure PSReadLine for PMC
    Set-PSReadLineOption -PredictionSource None
    Set-PSReadLineOption -BellStyle None
    Write-PmcDebug -Level 1 -Category 'PSREADLINE' -Message "PSReadLine options configured"

    # Set up custom tab completion with extensive debug logging
    Set-PSReadLineKeyHandler -Key Tab -ScriptBlock {
        try {
            Write-PmcDebug -Level 1 -Category 'TAB' -Message "Tab key handler triggered"

            # Get current line buffer
            $line = $null
            $cursor = $null
            [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

            Write-PmcDebug -Level 1 -Category 'TAB' -Message "Buffer state retrieved" -Data @{ Line = $line; Cursor = $cursor }

            # Use AST-based completion system
            $completions = @()
            if (Get-Command Get-PmcCompletionsFromAst -ErrorAction SilentlyContinue) {
                Write-PmcDebug -Level 1 -Category 'TAB' -Message "Using AST-based completion"
                try {
                    $completions = Get-PmcCompletionsFromAst -Buffer $line -CursorPos $cursor
                    Write-PmcDebug -Level 1 -Category 'TAB' -Message "AST completions generated" -Data @{ Count = $completions.Count }
                } catch {
                    Write-PmcDebug -Level 1 -Category 'TAB' -Message "AST completion failed: $_" -Data @{ Line = $line; Cursor = $cursor }
                    Write-PmcStyled -Style 'Error' -Text "AST completion failed: $_"
                    return
                }
            } else {
                Write-PmcDebug -Level 1 -Category 'TAB' -Message "AST completion not available - using default tab"
                [Microsoft.PowerShell.PSConsoleReadLine]::TabCompleteNext()
                return
            }

            # Handle completions

            if ($completions.Count -eq 0) {
                Write-PmcDebug -Level 1 -Category 'TAB' -Message "No completions found - using default tab"
                [Microsoft.PowerShell.PSConsoleReadLine]::TabCompleteNext()
            } elseif ($completions.Count -eq 1) {
                Write-PmcDebug -Level 1 -Category 'TAB' -Message "Single completion - replacing line" -Data @{ Completion = $completions[0] }
                [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert($completions[0])
            } else {
                Write-PmcDebug -Level 1 -Category 'TAB' -Message "Multiple completions - using default tab menu" -Data @{ CompletionCount = $completions.Count }
                [Microsoft.PowerShell.PSConsoleReadLine]::TabCompleteNext()
            }
        } catch {
            Write-PmcDebug -Level 1 -Category 'TAB' -Message "Tab completion error" -Data @{ Error = $_.ToString() }
            [Microsoft.PowerShell.PSConsoleReadLine]::TabCompleteNext()
        }
    }
    Write-PmcDebug -Level 1 -Category 'PSREADLINE' -Message "Tab completion handler registered"
}

function Read-PmcCommand {
    # Initialize PSReadLine on first use - crash if it fails
    if (-not $Script:PmcPSReadLineInitialized) {
        Initialize-PmcPSReadLine
        $Script:PmcPSReadLineInitialized = $true
    }

    Write-PmcDebug -Level 2 -Category 'INPUT' -Message "Reading command with Read-Host"

    # Use Read-Host - tab completion will be handled manually if needed
    $input = Read-Host -Prompt "pmc"

    Write-PmcDebug -Level 2 -Category 'INPUT' -Message "Input received" -Data @{ Input = $input }

    # Basic tab completion simulation - check for completion requests
    if ($input -and $input.EndsWith("?")) {
        # User requested help with "command?"
        $cleanInput = $input.TrimEnd("?").Trim()
        if ($cleanInput) {
            $tokens = $cleanInput -split '\s+' | Where-Object { $_ }
            if ($tokens.Count -eq 1) {
                try {
                    $commandMap = $null
                    if (Get-Variable -Name 'PmcCommandMap' -Scope Script -ErrorAction SilentlyContinue) {
                        $commandMap = (Get-Variable -Name 'PmcCommandMap' -Scope Script).Value
                    }

                    if ($commandMap -and $commandMap.Keys) {
                        $domains = @($commandMap.Keys) + @('help', 'exit', 'quit', 'status')
                        $matches = $domains | Where-Object { $_ -like "$($tokens[0])*" }
                        if ($matches -and $matches.Count -gt 0) {
                            Write-Host "Available completions for '$($tokens[0])': $($matches -join ', ')" -ForegroundColor Yellow
                            Write-PmcDebug -Level 2 -Category 'INPUT' -Message "Showing help completions" -Data @{ Prefix = $tokens[0]; Matches = $matches }
                        }
                    }
                } catch {
                    Write-PmcDebug -Level 1 -Category 'INPUT' -Message "Error in help completion" -Data @{ Error = $_.ToString() }
                }
            }
        }
        return ""  # Don't process the help request as a command
    }

    return $input
}

# Compatibility functions
function Enable-PmcInteractiveMode {
    Initialize-PmcPSReadLine
    return $true
}

function Disable-PmcInteractiveMode {
    # Nothing to clean up
}

function Get-PmcInteractiveStatus {
    return @{
        Enabled = $true
        Features = @("PSReadLine", "TabCompletion", "History")
        Engine = "PSReadLine"
        PSReadLineAvailable = $true
    }
}

# END FILE: ./module/Pmc.Strict/src/InputEngine.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/Interactive.ps1
# SIZE: 65.77 KB
# MODIFIED: 2025-09-24 04:55:54
# ================================================================================

# t2.ps1-Style Interactive Engine for PMC
# Complete implementation with inline cycling, history, undo/redo, and comprehensive instrumentation
# IMPORTANT: Completions MUST be plain strings. PSObjects/PSCustomObject and
# PSReadLine-style completion objects are not supported by this custom Console.ReadKey
# engine. Using objects breaks input flow and causes type/serialization errors.

Set-StrictMode -Version Latest

# Completions are simple strings throughout the system
# Classes remain defined in the main .psm1 file if needed elsewhere

# Centralized interactive state accessors (state-only)
function Pmc-GetEditor { $e = Get-PmcState -Section 'Interactive' -Key 'Editor'; if ($null -eq $e) { $e = [PmcEditorState]::new(); Set-PmcState -Section 'Interactive' -Key 'Editor' -Value $e }; return $e }
function Pmc-SetEditor($e) { Set-PmcState -Section 'Interactive' -Key 'Editor' -Value $e }
function Pmc-GetCache { $c = Get-PmcState -Section 'Interactive' -Key 'CompletionCache'; if ($null -eq $c) { $c=@{}; Set-PmcState -Section 'Interactive' -Key 'CompletionCache' -Value $c }; return $c }
function Pmc-SetCache($c) { Set-PmcState -Section 'Interactive' -Key 'CompletionCache' -Value $c }
function Pmc-ClearCache { $c = Pmc-GetCache; $c.Clear() | Out-Null; Pmc-SetCache $c }
function Pmc-GetGhost { $g = Get-PmcState -Section 'Interactive' -Key 'GhostTextEnabled'; if ($null -eq $g) { $g=$false; Set-PmcState -Section 'Interactive' -Key 'GhostTextEnabled' -Value $g }; return [bool]$g }
function Pmc-SetGhost([bool]$g) { Set-PmcState -Section 'Interactive' -Key 'GhostTextEnabled' -Value $g }
function Pmc-GetInfoMap { $m = Get-PmcState -Section 'Interactive' -Key 'CompletionInfoMap'; if ($null -eq $m) { $m=@{}; Set-PmcState -Section 'Interactive' -Key 'CompletionInfoMap' -Value $m }; return $m }
function Pmc-SetInfoMap($m) { Set-PmcState -Section 'Interactive' -Key 'CompletionInfoMap' -Value $m }

# Insert literal text at cursor and re-render input line
function Pmc-InsertAtCursor {
    param([Parameter(Mandatory=$true)][string]$Text)
    try {
        $ed = Pmc-GetEditor
        $before = $ed.Buffer
        $pos = [Math]::Max(0, [Math]::Min($ed.CursorPos, $before.Length))
        $ed.Buffer = $before.Substring(0, $pos) + $Text + $before.Substring($pos)
        $ed.CursorPos = $pos + $Text.Length
        Render-Interactive -Buffer $ed.Buffer -CursorPos $ed.CursorPos -InCompletion $false
    } catch {}
}

# Fuzzy matching utilities (subsequence with ranking)
function Invoke-PmcFuzzyFilter {
    param(
        [string[]] $Items,
        [string] $Query
    )
    if (-not $Items) { return @() }
    if ([string]::IsNullOrWhiteSpace($Query)) { return ,@($Items) }

    $q = $Query.ToLowerInvariant()
    $scored = @()
    foreach ($it in $Items) {
        $s = [string]$it
        $t = $s.ToLowerInvariant()
        $rank = $null
        if ($t.StartsWith($q)) { $rank = 0 }
        elseif ($t.Contains($q)) { $rank = 1 }
        elseif (Test-PmcSubsequence -Haystack $t -Needle $q) { $rank = 2 }
        if ($rank -ne $null) { $scored += [pscustomobject]@{ Item=$s; Rank=$rank } }
    }
    $ordered = $scored | Sort-Object Rank, @{Expression={$_.Item.Length}; Ascending=$true}, Item
    return @($ordered | Select-Object -ExpandProperty Item)
}

function Test-PmcSubsequence {
    param([string] $Haystack, [string] $Needle)
    if ([string]::IsNullOrEmpty($Needle)) { return $true }
    $i = 0; $j = 0
    while ($i -lt $Haystack.Length -and $j -lt $Needle.Length) {
        if ($Haystack[$i] -eq $Needle[$j]) { $j++ }
        $i++
    }
    return ($j -eq $Needle.Length)
}

function Initialize-PmcCompletionInfoMap {
    $map = @{}

    # Domain descriptions
    $map['task']      = @{ Description = 'Task management';       Category = 'Domain' }
    $map['project']   = @{ Description = 'Project management';     Category = 'Domain' }
    $map['time']      = @{ Description = 'Time logging/reporting'; Category = 'Domain' }
    $map['timer']     = @{ Description = 'Timers';                 Category = 'Domain' }
    $map['view']      = @{ Description = 'Predefined views';       Category = 'Domain' }
    $map['focus']     = @{ Description = 'Focus mode';             Category = 'Domain' }
    $map['system']    = @{ Description = 'System ops';             Category = 'Domain' }
    $map['config']    = @{ Description = 'Configuration';          Category = 'Domain' }
    $map['excel']     = @{ Description = 'Excel I/O';              Category = 'Domain' }
    $map['theme']     = @{ Description = 'Theme settings';         Category = 'Domain' }
    $map['activity']  = @{ Description = 'Activity log';           Category = 'Domain' }
    $map['template']  = @{ Description = 'Templates';              Category = 'Domain' }
    $map['recurring'] = @{ Description = 'Recurring rules';        Category = 'Domain' }
    $map['alias']     = @{ Description = 'Aliases';                Category = 'Domain' }
    $map['dep']       = @{ Description = 'Dependencies';           Category = 'Domain' }
    $map['import']    = @{ Description = 'Import data';            Category = 'Domain' }
    $map['export']    = @{ Description = 'Export data';            Category = 'Domain' }
    $map['show']      = @{ Description = 'Show info';              Category = 'Domain' }
    $map['interactive']= @{ Description = 'Interactive mode';      Category = 'Domain' }
    $map['help']      = @{ Description = 'Help';                   Category = 'Domain' }

    # Domain:Action descriptions (keyed as "domain:action")
    $pairs = @(
        'task:add=Add new task','task:list=List tasks','task:done=Mark task done','task:edit=Edit task','task:delete=Delete task','task:view=View task','task:search=Search tasks',
        'project:add=Add project','project:list=List projects','project:view=View project','project:update=Update project','project:rename=Rename project','project:delete=Delete project','project:archive=Archive project','project:set-fields=Set custom fields','project:show-fields=Show custom fields','project:stats=Project statistics','project:info=Project info','project:recent=Recent projects',
        'time:log=Log time','time:list=List entries','time:report=Report','time:edit=Edit entries',
        'timer:start=Start timer','timer:stop=Stop timer','timer:status=Timer status',
        'view:today=Today view','view:tomorrow=Tomorrow view','view:overdue=Overdue tasks','view:upcoming=Upcoming','view:blocked=Blocked','view:noduedate=No due date','view:projects=Projects overview','view:next=Next actions',
        'focus:set=Set focus','focus:clear=Clear focus','focus:status=Focus status',
        'system:undo=Undo last action','system:redo=Redo last action','system:backup=Create backup','system:clean=Clean data',
        'config:show=Show config','config:edit=Edit config','config:set=Set config','config:icons=Icon config',
        'excel:import=Import from Excel','excel:view=View excel output','excel:export=Export to Excel',
        'theme:set=Set theme','theme:list=List themes','theme:create=Create theme','theme:edit=Edit theme',
        'activity:log=Log activity','activity:list=List activity','activity:report=Activity report',
        'template:create=Create template','template:list=List templates','template:apply=Apply template','template:edit=Edit template','template:delete=Delete template',
        'recurring:add=Add recurring rule','recurring:list=List recurring rules','recurring:edit=Edit recurring rule','recurring:delete=Delete recurring rule','recurring:process=Process recurring',
        'alias:add=Add alias','alias:list=List aliases','alias:edit=Edit alias','alias:delete=Delete alias',
        'dep:add=Add dependency','dep:list=List dependencies','dep:remove=Remove dependency','dep:check=Check dependencies',
        'import:excel=Import from Excel','import:csv=Import from CSV','import:json=Import from JSON','import:outlook=Import from Outlook',
        'export:excel=Export to Excel','export:csv=Export to CSV','export:json=Export to JSON','export:ical=Export to iCal',
        'show:status=Show status','show:config=Show config','show:help=Show help','show:version=Show version',
        'interactive:enable=Enable interactive','interactive:disable=Disable interactive','interactive:status=Interactive status',
        'help:commands=Help commands','help:examples=Help examples','help:guide=Help guide','help:quick=Quick help'
    )
    foreach ($pair in $pairs) {
        $kv = $pair.Split('=')
        $map[$kv[0]] = @{ Description = $kv[1]; Category = 'Action' }
    }

    # Common argument suggestions
    $map['due:today'] = @{ Description = 'Due today';    Category = 'Argument' }
    $map['due:tomorrow'] = @{ Description = 'Due tomorrow'; Category = 'Argument' }
    $map['due:friday'] = @{ Description = 'Due Friday';  Category = 'Argument' }
    $map['due:+1w'] = @{ Description = 'Due +1 week';    Category = 'Argument' }
    $map['due:+1m'] = @{ Description = 'Due +1 month';   Category = 'Argument' }
    $map['p1'] = @{ Description = 'Priority 1'; Category = 'Argument' }
    $map['p2'] = @{ Description = 'Priority 2'; Category = 'Argument' }
    $map['p3'] = @{ Description = 'Priority 3'; Category = 'Argument' }
    $map['#urgent'] = @{ Description = 'Urgent tag'; Category = 'Argument' }
    $map['#bug']    = @{ Description = 'Bug tag'; Category = 'Argument' }
    $map['#feature']= @{ Description = 'Feature tag'; Category = 'Argument' }
    $map['#review'] = @{ Description = 'Review tag'; Category = 'Argument' }

    Pmc-SetInfoMap $map
}

function Get-PmcCompletionInfo {
    param(
        [string] $Domain,
        [string] $Action,
        [string] $Text
    )
    if ($Action) {
        $d = $null
        if ($Domain) { $d = $Domain.ToLower() }
        $a = $Action.ToLower()
        $key = "${d}:${a}"
        return (Pmc-GetInfoMap)[$key]
    }
    if ($Text) { return (Pmc-GetInfoMap)[$Text.ToLower()] }
    return $null
}

# High-level renderer that computes transient help text before delegating to Render-Line
function Render-Interactive {
    param(
        [string] $Buffer,
        [int] $CursorPos,
        [int] $IndicatorIndex = 0,
        [int] $IndicatorCount = 0,
        [bool] $InCompletion = $false
    )

    $helpText = $null
    $ghostText = ""
    if (-not $InCompletion) {
        try {
            $ctx = Parse-CompletionContext -Buffer $Buffer -CursorPos $CursorPos
            if ($ctx.Mode -eq [PmcCompletionMode]::Domain) {
                if ($ctx.CurrentToken) {
                    $info = Get-PmcCompletionInfo -Text $ctx.CurrentToken
                    if ($info) { $helpText = $info.Description }
                }
            } elseif ($ctx.Mode -eq [PmcCompletionMode]::Action) {
                if ($ctx.Tokens.Count -gt 0 -and $ctx.CurrentToken) {
                    $info = Get-PmcCompletionInfo -Domain $ctx.Tokens[0] -Action $ctx.CurrentToken
                    $summary = Pmc-FormatSchemaSummary -Domain $ctx.Tokens[0] -Action $ctx.CurrentToken
                    if ($summary) { $helpText = $summary }
                    elseif ($info) { $helpText = $info.Description }
                }
            } elseif ($ctx.Mode -eq [PmcCompletionMode]::Arguments) {
                $dom = $null; if ($ctx.Tokens.Count -gt 0) { $dom = $ctx.Tokens[0] }
                $act = $null; if ($ctx.Tokens.Count -gt 1) { $act = $ctx.Tokens[1] }
                if ($dom -and $act) {
                    $summary = Pmc-FormatSchemaSummary -Domain $dom -Action $act
                    if ($summary) { $helpText = $summary }
                } elseif ($ctx.CurrentToken) {
                    $info = Get-PmcCompletionInfo -Text $ctx.CurrentToken
                    if ($info) { $helpText = $info.Description }
                }
            }
            # Compute ghost text (inline suggestion) - DISABLED
            $ghostText = ""

            # No numeric suggestion line; keep help minimal and passive
        } catch {}
    }

    Render-Line -Buffer $Buffer -CursorPos $CursorPos -IndicatorIndex $IndicatorIndex -IndicatorCount $IndicatorCount -InCompletion $InCompletion -HelpText $helpText -GhostText $ghostText
}

# Build a compact argument summary from schema for inline guidance
function Pmc-FormatSchemaSummary {
    param([string]$Domain,[string]$Action)
    if (-not $Domain -or -not $Action) { return $null }
    try {
        $schema = Get-PmcSchema -Domain $Domain -Action $Action
        if (-not $schema -or @($schema).Count -eq 0) { return $null }
        $parts = @()
        foreach ($def in $schema) {
            $name = [string]$def['Name']
            $type = [string]$def['Type']
            $prefix = [string]$def['Prefix']
            $req = [bool]$def['Required']
            $allowsMulti = [bool]$def['AllowsMultiple']

            $token = $null
            switch ($type) {
                'ProjectName' { $token = '@project' }
                'Priority'    { $token = 'p1|p2|p3' }
                'DateString'  { $token = 'due:YYYY-MM-DD' }
                'TagName'     { if ($allowsMulti) { $token = '#tag...' } else { $token = '#tag' } }
                'TaskID'      { $token = '<id>' }
                'Duration'    { $token = '<duration>' }
                'DateRange'   { $token = '<range>' }
                default {
                    if ($prefix) { $token = "$prefix$name" }
                    elseif ($name -match '^(?i)text$') { $token = '<text>' }
                    else { $token = "<$name>" }
                }
            }

            if (-not $req) { $token = "[$token]" }
            $parts += $token
        }
        if ($parts.Count -gt 0) { return ('Args: ' + ($parts -join ' ')) }
    } catch {}
    return $null
}

# Helper function removed - we now use simple strings instead of PSCustomObjects
# This eliminates the dual completion path issue where PSCustomObjects were being created

# Debug helper: log state transitions at Debug2
function Write-StateChange {
    param(
        [string] $KeyName,
        [hashtable] $BeforeCtx,
        [bool] $BeforeInCompletion
    )
    try {
        $ed = Pmc-GetEditor
        $afterCtx = Parse-CompletionContext -Buffer $ed.Buffer -CursorPos $ed.CursorPos
        $afterIn = $ed.InCompletion
        Write-PmcDebug -Level 2 -Category 'STATE' -Message "Key=$KeyName InCompletion: $BeforeInCompletion->$afterIn Mode: $($BeforeCtx.Mode)->$($afterCtx.Mode) BufferLen=$($ed.Buffer.Length) Cursor=$($ed.CursorPos)"
    } catch {
        # Ghost text computation failed - return empty string
    }
}

# Compute ghost hint text based on current context (pure)
function Compute-GhostText {
    param(
        [string] $Buffer,
        [hashtable] $Context
    )

    if (-not (Pmc-GetGhost)) { return "" }

    try {
        $ghost = ""
        $hasTrailingSpace = $Buffer.EndsWith(' ')

        if ($Context.Mode -eq [PmcCompletionMode]::Domain) {
            # Show domain hints when starting or when current token is incomplete
            if ([string]::IsNullOrEmpty($Context.CurrentToken) -or -not $hasTrailingSpace) {
                $ghost = " task|project|time..."
            }
        } elseif ($Context.Mode -eq [PmcCompletionMode]::Action) {
            # Show action hints when we have a domain and are ready for action
            if ($Context.Tokens.Count -ge 1 -and $hasTrailingSpace) {
                $domain = $Context.Tokens[0].ToLower()
                switch ($domain) {
                    'task' { $ghost = " add|list|done|edit" }
                    'project' { $ghost = " add|list|view|edit" }
                    'time' { $ghost = " log|report|list" }
                    'timer' { $ghost = " start|stop|status" }
                    'view' { $ghost = " today|tomorrow|overdue" }
                    'focus' { $ghost = " set|clear|status" }
                    'system' { $ghost = " undo|redo|backup" }
                    'config' { $ghost = " show|edit|set" }
                    default { $ghost = " help" }
                }
            }
        } elseif ($Context.Mode -eq [PmcCompletionMode]::Arguments) {
            # Show argument hints when we have domain and action
            if ($Context.Tokens.Count -ge 2 -and $hasTrailingSpace) {
                $ghost = " @project due:date p1-3 #tags"
            }
        }

        Write-PmcDebug -Level 3 -Category 'GHOST' -Message "Ghost computation: Mode=$($Context.Mode), Tokens=[$($Context.Tokens -join ', ')], HasTrailingSpace=$hasTrailingSpace, Ghost='$ghost'"
        return ($ghost ?? "")
    } catch {
        Write-PmcDebug -Level 1 -Category 'GHOST' -Message "Ghost computation error: $_"
        return ""
    }
}

# Get terminal dimensions for TUI layout
function Get-TerminalSize {
    return [PmcTerminalService]::GetDimensions()
}

# Clear screen and position cursor for command output
function Clear-CommandOutput {
    [Console]::Write("`e[2J`e[H")  # Clear screen + move to top
    [Console]::Out.Flush()
}

# Simplified inline renderer for compatibility
function Render-Line {
    param(
        [string] $Buffer,
        [int] $CursorPos,
        [int] $IndicatorIndex = 0,
        [int] $IndicatorCount = 0,
        [bool] $InCompletion = $false,
        [string] $HelpText = $null,
        [string] $GhostText = $null
    )

    $prompt = "pmc> "
    $promptLen = $prompt.Length

    # Compute indicator text
    $indicatorText = ''
    if ($IndicatorCount -gt 1) {
        $displayIndex = [Math]::Max(1, $IndicatorIndex)
        $indicatorText = " ($displayIndex/$IndicatorCount)"
    }

    # Two-line HUD: input at last-1 row, help at last row
    $term = Get-TerminalSize
    $inputRow = [Math]::Max(1, $term.Height - 1)
    $helpRow = $term.Height

    # Compute visible input line (truncate to width)
    $lineCore = "$prompt$Buffer$indicatorText"
    if ($lineCore.Length -gt $term.Width) {
        # Prefer to keep cursor region visible; simple right-trim for now
        $lineCore = $lineCore.Substring(0, $term.Width)
    }

    # Compute help line (truncate to width)
    $helpOut = ''
    if ($HelpText -and $HelpText.Trim().Length -gt 0) {
        $helpOut = $HelpText.Trim()
        if ($helpOut.Length -gt $term.Width) { $helpOut = $helpOut.Substring(0, $term.Width) }
    }

    # Clear the two bottom lines and render
    [Console]::Write("`e[${inputRow};1H`e[2K")
    [Console]::Write($lineCore)

    # Ghost text rendering disabled
    [Console]::Write("`e[${helpRow};1H`e[2K")
    if ($helpOut) { [Console]::Write($helpOut) }
    [Console]::Out.Flush()

    # Restore cursor to input line/column
    # Place caret at the insertion point (after the last typed character)
    $targetCol = [Math]::Min($term.Width, $promptLen + $CursorPos + 1)
    if ($targetCol -lt 1) { $targetCol = 1 }
    [Console]::Write("`e[${inputRow};${targetCol}H")
    [Console]::Out.Flush()

    Write-PmcDebug -Level 2 -Category 'RENDER' -Message "Bottom HUD render: bufferLen=$($Buffer.Length), cursorPos=$CursorPos, width=$($term.Width)"
}

# No conversion factory: completions are plain strings by design

# Tokenization: compute current token boundaries for replacement
function Get-TokenBoundaries {
    param(
        [string] $Buffer,
        [int] $CursorPos
    )

    if ([string]::IsNullOrEmpty($Buffer)) {
        return @{ Start = 0; End = 0; Token = "" }
    }

    # Find token boundaries around cursor
    $start = $CursorPos
    $end = $CursorPos

    # Move start backward to beginning of current token
    while ($start -gt 0 -and $Buffer[$start - 1] -ne ' ') {
        $start--
    }

    # Move end forward to end of current token
    while ($end -lt $Buffer.Length -and $Buffer[$end] -ne ' ') {
        $end++
    }

    $token = if ($start -lt $Buffer.Length -and $end -gt $start) {
        $Buffer.Substring($start, $end - $start)
    } else {
        ""
    }

    return @{
        Start = $start
        End = $end
        Token = $token
    }
}

# Parse buffer to determine completion mode and context
function Parse-CompletionContext {
    param(
        [string] $Buffer,
        [int] $CursorPos
    )

    # Use the same tokenizer as the rest of the system for consistency
    $tokens = ConvertTo-PmcTokens $Buffer
    $tokenInfo = Get-TokenBoundaries -Buffer $Buffer -CursorPos $CursorPos

    $mode = [PmcCompletionMode]::Domain
    $currentToken = $tokenInfo.Token

    # Determine completion mode based on token position and trailing space
    $hasTrailingSpace = $Buffer.EndsWith(' ')

    if ($tokens.Count -eq 0) {
        $mode = [PmcCompletionMode]::Domain
    } elseif ($tokens.Count -eq 1 -and -not $hasTrailingSpace) {
        # Still typing first token (domain)
        $mode = [PmcCompletionMode]::Domain
    } elseif ($tokens.Count -eq 1 -and $hasTrailingSpace) {
        # First token complete, ready for action
        $mode = [PmcCompletionMode]::Action
    } elseif ($tokens.Count -eq 2 -and -not $hasTrailingSpace) {
        # Still typing second token (action)
        $mode = [PmcCompletionMode]::Action
    } elseif ($tokens.Count -eq 2 -and $hasTrailingSpace) {
        # Domain and action complete, ready for arguments
        $mode = [PmcCompletionMode]::Arguments
    } elseif ($tokens.Count -ge 3) {
        # In arguments phase
        $mode = [PmcCompletionMode]::Arguments
    } else {
        $mode = [PmcCompletionMode]::FreeText
    }

    Write-PmcDebug -Level 3 -Category 'COMPLETION' -Message "Parsed context: Tokens=[$($tokens -join ', ')], Mode=$mode (tokenCount=$($tokens.Count), hasTrailingSpace=$hasTrailingSpace)"

    return @{
        Mode = $mode
        CurrentToken = $currentToken
        TokenStart = $tokenInfo.Start
        TokenEnd = $tokenInfo.End
        Tokens = $tokens
    }
}

# Domain completion provider
function Get-PmcDomainCompletions {
    param(
        [string] $Filter = ""
    )

    Write-PmcDebug -Level 2 -Category 'COMPLETION' -Message "Getting domain completions for filter='$Filter'"

    try {
        # Simple string array - no objects, no type conversion issues
        $domains = @(
            "task", "project", "time", "timer", "view", "focus",
            "system", "config", "excel", "theme", "activity",
            "template", "recurring", "alias", "dep", "import",
            "export", "show", "interactive", "help"
        )

        # Add shortcut commands from the shortcut map
        $shortcuts = @()
        if ($Script:PmcShortcutMap -and $Script:PmcShortcutMap.Keys) {
            $shortcuts = @($Script:PmcShortcutMap.Keys)
        }

        # Combine domains and shortcuts
        $allCompletions = $domains + $shortcuts

        $result = Invoke-PmcFuzzyFilter -Items $allCompletions -Query $Filter
        Write-PmcDebug -Level 2 -Category 'COMPLETION' -Message "Domain completions: found $(@($result).Count) items"
        return ,@($result)

    } catch {
        Write-PmcDebug -Level 1 -Category 'COMPLETION' -Message "Domain completion error: $_"
        return @()
    }
}

# Action completion provider
function Get-PmcActionCompletions {
    param([string] $Domain = "", [string] $Filter = "")

    Write-PmcDebug -Level 2 -Category 'COMPLETION' -Message "Getting action completions for domain='$Domain', filter='$Filter'"

    try {
        $actions = @()

        switch ($Domain.ToLower()) {
            'task' {
                $actions = @("add", "list", "done", "edit", "delete", "view", "search")
            }
            'project' {
                $actions = @("add", "list", "view", "update", "rename", "delete", "archive", "set-fields", "show-fields", "stats", "info", "recent")
            }
            'time' {
                $actions = @("log", "list", "report", "edit")
            }
            'timer' {
                $actions = @("start", "stop", "status")
            }
            'view' {
                $actions = @("today", "tomorrow", "overdue", "upcoming", "blocked", "noduedate", "projects", "next")
            }
            'focus' {
                $actions = @("set", "clear", "status")
            }
            'system' {
                $actions = @("undo", "redo", "backup", "clean")
            }
            'config' {
                $actions = @("show", "edit", "set", "icons")
            }
            'excel' {
                $actions = @("import", "view", "export")
            }
            'theme' {
                $actions = @("set", "list", "create", "edit")
            }
            'activity' {
                $actions = @("log", "list", "report")
            }
            'template' {
                $actions = @("create", "list", "apply", "edit", "delete")
            }
            'recurring' {
                $actions = @("add", "list", "edit", "delete", "process")
            }
            'alias' {
                $actions = @("add", "list", "edit", "delete")
            }
            'dep' {
                $actions = @("add", "list", "remove", "check")
            }
            'import' {
                $actions = @("excel", "csv", "json", "outlook")
            }
            'export' {
                $actions = @("excel", "csv", "json", "ical")
            }
            'show' {
                $actions = @("status", "config", "help", "version")
            }
            'interactive' {
                $actions = @("enable", "disable", "status")
            }
            'help' {
                $actions = @("commands", "examples", "guide", "quick")
            }
            default {
                return @()
            }
        }

        $result = Invoke-PmcFuzzyFilter -Items $actions -Query $Filter
        Write-PmcDebug -Level 2 -Category 'COMPLETION' -Message "Action completions: found $(@($result).Count) items"
        return ,@($result)

    } catch {
        Write-PmcDebug -Level 1 -Category 'COMPLETION' -Message "Error in Get-PmcActionCompletions: $_"
        return @()
    }
}

# Argument completion provider (projects, dates, priorities, etc.)
function Get-PmcArgumentCompletions {
    param(
        [string] $Domain,
        [string] $Action,
        [string] $Filter = ""
    )

    Write-PmcDebug -Level 2 -Category 'COMPLETION' -Message "Getting argument completions for domain='$Domain' action='$Action' filter='$Filter'"

    try {
        $completions = @()

        # Project completions (@project)
        if ($Filter.StartsWith('@') -or [string]::IsNullOrEmpty($Filter)) {
            try {
                $data = Get-PmcData
                $projects = @($data.projects)
                $all = @()
                foreach ($project in $projects) { $all += ("@" + [string]$project.name) }
                $needle = if ($Filter -like '@*') { $Filter } else { '@' + $Filter }
                $filtered = Invoke-PmcFuzzyFilter -Items $all -Query $needle
                $completions += $filtered
            } catch {
                Write-PmcDebug -Level 2 -Category 'COMPLETION' -Message "Project loading error: $_"
            }
        }

        # Date completions (due:)
        if ($Filter.StartsWith('due') -or [string]::IsNullOrWhiteSpace($Filter)) {
            $dates = @("due:today", "due:tomorrow", "due:friday", "due:+1w", "due:+1m", "due>today", "due<today", "due>=today", "due<=today", "due>2024-12-31", "due<2024-12-31")
            $completions += (Invoke-PmcFuzzyFilter -Items $dates -Query $Filter)
        }

        # Priority completions
        if ($Filter.StartsWith('p') -or [string]::IsNullOrWhiteSpace($Filter)) {
            $priorities = @("p1", "p2", "p3", "p<=1", "p<=2", "p<=3", "p>=1", "p>=2", "p>=3", "p>1", "p>2", "p<2", "p<3")
            $completions += (Invoke-PmcFuzzyFilter -Items $priorities -Query $Filter)
        }

        # '#' handling: for time log, '#' means ID1 time codes (2-5 digits).
        # Otherwise, '#' is tag completion.
        if ($Filter.StartsWith('#') -or [string]::IsNullOrWhiteSpace($Filter)) {
            if (($Domain -eq 'time') -and ($Action -eq 'log')) {
                try {
                    $data = Get-PmcDataAlias
                    $codes = @()
                    foreach ($l in $data.timelogs) {
                        try { if ($l.PSObject.Properties['id1'] -and $l.id1 -match '^\d{2,5}$') { $codes += ('#' + [string]$l.id1) } } catch {}
                    }
                    $codes = @($codes | Select-Object -Unique)
                    if ($codes.Count -gt 0) { $completions += (Invoke-PmcFuzzyFilter -Items $codes -Query $Filter) }
                } catch {}
            } else {
                $tags = @()
                try {
                    $data = Get-PmcDataAlias
                    foreach ($t in $data.tasks) {
                        try {
                            if ($t -and $t.PSObject.Properties['tags']) {
                                foreach ($tg in @($t.tags)) { if ($tg) { $tags += ("#" + [string]$tg) } }
                            }
                        } catch {}
                    }
                } catch {}
                if ($tags.Count -eq 0) { $tags = @("#urgent", "#todo", "#review") }
                $tags = @($tags | Select-Object -Unique)
                $completions += (Invoke-PmcFuzzyFilter -Items $tags -Query $Filter)
            }
        }

        # Add query history suggestions if no specific prefix
        if ([string]::IsNullOrWhiteSpace($Filter) -or ($Filter.Length -eq 1 -and $Filter -match '^[a-z]$')) {
            try {
                $history = Get-PmcQueryHistory -Last 5
                $historyCompletions = @()
                foreach ($h in $history) {
                    if ($h -and $h.Trim() -ne '' -and $h -notlike "*$Filter*") { continue }
                    $historyCompletions += "◄ $h"
                }
                $completions += $historyCompletions
            } catch {
                Write-PmcDebug -Level 2 -Category 'COMPLETION' -Message "History loading error: $_"
            }
        }

        Write-PmcDebug -Level 2 -Category 'COMPLETION' -Message "Argument completions: found $(@($completions).Count) items"
        return ,@($completions)

    } catch {
        Write-PmcDebug -Level 1 -Category 'COMPLETION' -Message "Argument completion error: $_"
        return @()
    }
}

# Get completions with caching and comprehensive instrumentation
function Get-CompletionsForState {
    param(
        [hashtable] $Context
    )

    # Try AST-based completion first
    try {
        if (Get-Command Get-PmcCompletionsFromAst -ErrorAction SilentlyContinue) {
            $buffer = if ($Context.Buffer) { $Context.Buffer } else { ($Context.Tokens -join ' ') + $Context.CurrentToken }
            $cursorPos = if ($Context.CursorPos) { $Context.CursorPos } else { $buffer.Length }

            $astCompletions = Get-PmcCompletionsFromAst -Buffer $buffer -CursorPos $cursorPos

            if ($astCompletions.Count -gt 0) {
                Write-PmcDebug -Level 2 -Category 'COMPLETION' -Message "Using AST completions: found $($astCompletions.Count) items"
                return $astCompletions
            }
        }
    } catch {
        Write-PmcDebug -Level 2 -Category 'COMPLETION' -Message "AST completion failed: $_, falling back to legacy"
    }

    # Fallback to legacy completion system
    $cacheKey = "$($Context.Mode):$($Context.CurrentToken):$($Context.Tokens -join ' ')"

    Write-PmcDebug -Level 2 -Category 'COMPLETION' -Message "Start Tab cycle (legacy): state=$($Context.Mode), token='$($Context.CurrentToken)', tokens=$($Context.Tokens.Count)"

    # Check cache first for performance
    $cache = Pmc-GetCache
    if ($cache.ContainsKey($cacheKey)) {
        $cached = $cache[$cacheKey]
        # Cache hit - reduced verbosity
        return $cached
    }

    try {
        $completions = @()

        # Force argument completions when token starts with well-known prefixes
        $tok = $Context.CurrentToken
        $forceArg = ($tok -and ($tok.StartsWith('@') -or $tok.StartsWith('p') -or $tok.StartsWith('due:') -or $tok.StartsWith('#')))
        if ($forceArg) {
            $dom = if ($Context.Tokens.Count -gt 0) { $Context.Tokens[0] } else { '' }
            $act = if ($Context.Tokens.Count -gt 1) { $Context.Tokens[1] } else { '' }
            $completions = Get-PmcArgumentCompletions -Domain $dom -Action $act -Filter $tok
        } else {
            switch ($Context.Mode) {
                ([PmcCompletionMode]::Domain) {
                    $completions = Get-PmcDomainCompletions -Filter $Context.CurrentToken
                }
                ([PmcCompletionMode]::Action) {
                    if ($Context.Tokens.Count -gt 0) {
                        $completions = Get-PmcActionCompletions -Domain $Context.Tokens[0] -Filter $Context.CurrentToken
                    }
                }
                ([PmcCompletionMode]::Arguments) {
                    if ($Context.Tokens.Count -ge 2) {
                        $completions = Get-PmcArgumentCompletions -Domain $Context.Tokens[0] -Action $Context.Tokens[1] -Filter $Context.CurrentToken
                    }
                }
                default {
                    Write-PmcDebug -Level 2 -Category 'COMPLETION' -Message "Unknown completion mode: $($Context.Mode)"
                }
            }
        }

        # No type conversion needed - strings are stable

        # Cache results for performance
        $cache[$cacheKey] = $completions

        # Clean cache if it gets too large (simple LRU)
        if ($cache.Keys.Count -gt 100) { $cache.Clear() }
        Pmc-SetCache $cache

        $safeCount = if ($completions -is [array]) { $completions.Count } elseif ($completions) { 1 } else { 0 }
        $safeFirst3 = try { ($completions | Select-Object -First 3) -join ', ' } catch { 'N/A' }
        Write-PmcDebug -Level 2 -Category 'COMPLETION' -Message "Provider outputs: type=string[], length=$safeCount, first3=$safeFirst3"

        return $completions

    } catch {
        Write-PmcDebug -Level 1 -Category 'COMPLETION' -Message "Completion provider error: $_ | StackTrace: $($_.ScriptStackTrace)"
        return @()
    }
}

# Replace token in buffer with inline replacement
function Replace-TokenInBuffer {
    param(
        [string] $Buffer,
        [int] $TokenStart,
        [int] $TokenEnd,
        [string] $Replacement
    )

    if ($TokenStart -eq $TokenEnd) {
        # Insert at cursor position
        return $Buffer.Substring(0, $TokenStart) + $Replacement + $Buffer.Substring($TokenStart)
    } else {
        # Replace existing token
        return $Buffer.Substring(0, $TokenStart) + $Replacement + $Buffer.Substring($TokenEnd)
    }
}

# Ghost text system with inline positioning
# Clear ghost text (no-op with overlay model; kept for compatibility)
function Clear-GhostText { Write-Host -NoNewline "`e[0K" }

# History management
function Add-ToHistory {
    param([string] $Command)

    if ([string]::IsNullOrWhiteSpace($Command)) { return }

    # Don't add duplicate consecutive entries
    if ((Pmc-GetEditor).History.Count -gt 0 -and (Pmc-GetEditor).History[-1] -eq $Command) {
        return
    }

    (Pmc-GetEditor).History += $Command

    # Trim history if too long
    if ((Pmc-GetEditor).History.Count -gt (Pmc-GetEditor).MaxHistoryItems) {
        (Pmc-GetEditor).History = (Pmc-GetEditor).History[-(Pmc-GetEditor).MaxHistoryItems..-1]
    }

    (Pmc-GetEditor).HistoryIndex = (Pmc-GetEditor).History.Count
}

# Undo/Redo system
function Add-ToUndoStack {
    param([string] $State)

    (Pmc-GetEditor).UndoStack += $State
    (Pmc-GetEditor).RedoStack = @()  # Clear redo stack on new action

    if ((Pmc-GetEditor).UndoStack.Count -gt (Pmc-GetEditor).MaxUndoItems) {
        (Pmc-GetEditor).UndoStack = (Pmc-GetEditor).UndoStack[-(Pmc-GetEditor).MaxUndoItems..-1]
    }
}

# State snapshot for debugging exceptions
function Get-EditorStateSnapshot {
    $ed = Pmc-GetEditor
    return @{
        Buffer = $ed.Buffer
        CursorPos = $ed.CursorPos
        InCompletion = $ed.InCompletion
        CompletionCount = $ed.Completions.Count
        CompletionIndex = $ed.CompletionIndex
        Mode = $ed.Mode
        Timestamp = Get-Date
        CompletionDetails = ($ed.Completions | ForEach-Object { "$($_.GetType().Name):$($_)" }) -join '; '
    }
}

# Main command reader with comprehensive instrumentation
function Read-PmcCommand {
    Write-PmcDebug -Level 2 -Category 'INPUT' -Message "Starting Read-PmcCommand session"

    # Initialize or reset only the current line state (preserve history across prompts)
    $ed = Pmc-GetEditor
    if ($null -eq $ed) {
        $ed = [PmcEditorState]::new()
        Pmc-SetEditor $ed
    }
    $ed.Buffer = ''
    $ed.CursorPos = 0
    $ed.InCompletion = $false
    $ed.OriginalBuffer = ''
    $ed.Completions = @()
    $ed.CompletionIndex = -1
    $ed.Mode = [PmcCompletionMode]::Domain
    $ed.CurrentToken = ''
    $ed.TokenStart = 0
    $ed.TokenEnd = 0
    Pmc-SetEditor $ed

    # Initial prompt render
    try { Render-Interactive -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos -InCompletion $false } catch {}

    while ($true) {
        try {
            # Defensive I/O: verify Console.ReadKey is available

            $key = [Console]::ReadKey($true)
            # Key press details reduced to completion/input summaries only

        } catch {
            Write-PmcStyled -Style 'Error' -Text "Console.ReadKey failed: $_"
            Write-PmcStyled -Style 'Warning' -Text "Interactive mode not available (input redirected or no TTY)"
            break
        }

        # Save state for undo before major changes
        if ($key.Key -in @('Spacebar', 'Enter', 'Delete', 'Backspace')) {
            Add-ToUndoStack -State (Pmc-GetEditor).Buffer
        }

        try {
            switch ($key.Key) {
                'LeftArrow' {
                    if ((Pmc-GetEditor).CursorPos -gt 0) {
                        (Pmc-GetEditor).CursorPos--
                        Render-Interactive -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos -InCompletion $false
                    }
                    continue
                }
                'RightArrow' {
                    if ((Pmc-GetEditor).CursorPos -lt (Pmc-GetEditor).Buffer.Length) {
                        (Pmc-GetEditor).CursorPos++
                    }
                    Render-Interactive -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos -InCompletion $false
                    continue
                }
                'Home' {
                    (Pmc-GetEditor).CursorPos = 0
                    Render-Interactive -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos -InCompletion $false
                    continue
                }
                'End' {
                    (Pmc-GetEditor).CursorPos = (Pmc-GetEditor).Buffer.Length
                    Render-Interactive -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos -InCompletion $false
                    continue
                }
                'Delete' {
                    if ((Pmc-GetEditor).CursorPos -lt (Pmc-GetEditor).Buffer.Length) {
                        (Pmc-GetEditor).Buffer = (Pmc-GetEditor).Buffer.Remove((Pmc-GetEditor).CursorPos, 1)
                        Render-Interactive -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos -InCompletion $false
                    }
                    continue
                }
                # Removed Alt+1/2/3 quick-accept bindings to avoid input interference
                'Tab' {
                    $beforeCtx = Parse-CompletionContext -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos
                    $beforeIn = (Pmc-GetEditor).InCompletion
                    $isShiftTab = ($key.Modifiers -band [ConsoleModifiers]::Shift) -eq [ConsoleModifiers]::Shift
                    $direction = if ($isShiftTab) { "reverse" } else { "forward" }
                    Write-PmcDebug -Level 2 -Category 'INPUT' -Message "Tab key pressed (Shift=$isShiftTab): buffer='$((Pmc-GetEditor).Buffer)', cursor=$((Pmc-GetEditor).CursorPos), inCompletion=$((Pmc-GetEditor).InCompletion)"
                    Write-PmcDebug -Level 2 -Category 'COMPLETION' -Message "Tab cycle start: buffer='$((Pmc-GetEditor).Buffer)', cursor=$((Pmc-GetEditor).CursorPos), mode=initial, direction=$direction"

                    if (-not (Pmc-GetEditor).InCompletion) {
                        # First Tab: initialize completion cycling
                        (Pmc-GetEditor).OriginalBuffer = (Pmc-GetEditor).Buffer
                        $context = Parse-CompletionContext -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos
                        (Pmc-GetEditor).Mode = $context.Mode
                        (Pmc-GetEditor).CurrentToken = $context.CurrentToken
                        (Pmc-GetEditor).TokenStart = $context.TokenStart
                        (Pmc-GetEditor).TokenEnd = $context.TokenEnd

                        # Use unified completion system
                        (Pmc-GetEditor).Completions = Get-CompletionsForState -Context $context
                        $safeCompletionCount = if ((Pmc-GetEditor).Completions -is [array]) { (Pmc-GetEditor).Completions.Count } elseif ((Pmc-GetEditor).Completions) { 1 } else { 0 }
                        $safeCompletionFirst3 = try { ((Pmc-GetEditor).Completions | Select-Object -First 3) -join ', ' } catch { 'N/A' }
                        Write-PmcDebug -Level 2 -Category 'COMPLETION' -Message "Provider outputs: type=string[], length=$safeCompletionCount, first3=$safeCompletionFirst3"

                        if ($safeCompletionCount -gt 0) {
                            (Pmc-GetEditor).InCompletion = $true
                            # For Shift+Tab on first press, start at the end
                            (Pmc-GetEditor).CompletionIndex = if ($isShiftTab) { $safeCompletionCount - 1 } else { 0 }

                            # Replace token with selected completion
                            $firstCompletion = (Pmc-GetEditor).Completions[(Pmc-GetEditor).CompletionIndex]
                            (Pmc-GetEditor).Buffer = Replace-TokenInBuffer -Buffer (Pmc-GetEditor).Buffer -TokenStart (Pmc-GetEditor).TokenStart -TokenEnd (Pmc-GetEditor).TokenEnd -Replacement $firstCompletion
                            (Pmc-GetEditor).CursorPos = (Pmc-GetEditor).TokenStart + $firstCompletion.Length

                            # Render with indicator and transient help from aux map
                            $helpInfo = $null
                            if ((Pmc-GetEditor).Mode -eq [PmcCompletionMode]::Action -and $context.Tokens.Count -gt 0) {
                                $helpInfo = Get-PmcCompletionInfo -Domain $context.Tokens[0] -Action $firstCompletion
                            } else {
                                $helpInfo = Get-PmcCompletionInfo -Text $firstCompletion
                            }
                            $helpText = if ($helpInfo) { $helpInfo.Description } else { $null }
                            Render-Line -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos -IndicatorIndex 1 -IndicatorCount $safeCompletionCount -InCompletion $true -HelpText $helpText

                            Write-PmcDebug -Level 2 -Category 'COMPLETION' -Message "Before Tab accept: index=0, selected item type=$($firstCompletion.GetType().Name), text='$($firstCompletion)'"
                            Write-PmcDebug -Level 2 -Category 'COMPLETION' -Message "After Tab accept: new buffer='$((Pmc-GetEditor).Buffer)', phase=cycling (1/$safeCompletionCount)"
                        } else {
                        Write-Host "`r`e[0Kpmc> $((Pmc-GetEditor).Buffer) [no completions]" -NoNewline
                        Start-Sleep -Milliseconds 350
                        Render-Interactive -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos -InCompletion $false
                            Write-PmcDebug -Level 2 -Category 'COMPLETION' -Message "No completions found for context: $($context | ConvertTo-Json -Compress)"
                        }
                    } else {
                        # Cycle to next/previous completion based on direction
                        $safeCurrentCount = if ((Pmc-GetEditor).Completions -is [array]) { (Pmc-GetEditor).Completions.Count } elseif ((Pmc-GetEditor).Completions) { 1 } else { 0 }
                        if ($safeCurrentCount -gt 0) {
                        if ($isShiftTab) {
                            # Reverse direction (Shift+Tab)
                            (Pmc-GetEditor).CompletionIndex = ((Pmc-GetEditor).CompletionIndex - 1 + $safeCurrentCount) % $safeCurrentCount
                        } else {
                            # Forward direction (Tab)
                            (Pmc-GetEditor).CompletionIndex = ((Pmc-GetEditor).CompletionIndex + 1) % $safeCurrentCount
                        }
                    } else {
                        (Pmc-GetEditor).CompletionIndex = 0
                    }
                    $selectedCompletion = (Pmc-GetEditor).Completions[(Pmc-GetEditor).CompletionIndex]

                        # Replace token with cycled completion
                    (Pmc-GetEditor).Buffer = Replace-TokenInBuffer -Buffer (Pmc-GetEditor).OriginalBuffer -TokenStart (Pmc-GetEditor).TokenStart -TokenEnd (Pmc-GetEditor).TokenEnd -Replacement $selectedCompletion
                    (Pmc-GetEditor).CursorPos = (Pmc-GetEditor).TokenStart + $selectedCompletion.Length

                        # Render with indicator and transient help from aux map
                    $ctxForHelp = Parse-CompletionContext -Buffer (Pmc-GetEditor).OriginalBuffer -CursorPos (Pmc-GetEditor).TokenStart
                        $helpInfo = $null
                    if ((Pmc-GetEditor).Mode -eq [PmcCompletionMode]::Action -and $ctxForHelp.Tokens.Count -gt 0) {
                        $helpInfo = Get-PmcCompletionInfo -Domain $ctxForHelp.Tokens[0] -Action $selectedCompletion
                    } else {
                        $helpInfo = Get-PmcCompletionInfo -Text $selectedCompletion
                    }
                    $helpText = if ($helpInfo) { $helpInfo.Description } else { $null }
                    Render-Line -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos -IndicatorIndex ((Pmc-GetEditor).CompletionIndex + 1) -IndicatorCount $safeCurrentCount -InCompletion $true -HelpText $helpText

                    Write-PmcDebug -Level 2 -Category 'COMPLETION' -Message "Before Tab cycle ($direction): index=$((Pmc-GetEditor).CompletionIndex), selected item type=$($selectedCompletion.GetType().Name), text='$($selectedCompletion)'"
                    Write-PmcDebug -Level 2 -Category 'COMPLETION' -Message "After Tab cycle ($direction): new buffer='$((Pmc-GetEditor).Buffer)', phase=cycling ($((Pmc-GetEditor).CompletionIndex + 1)/$safeCurrentCount)"
                    }
                    Write-StateChange -KeyName 'Tab' -BeforeCtx $beforeCtx -BeforeInCompletion $beforeIn
                    continue
                }

                'Spacebar' {
                    $beforeCtx = Parse-CompletionContext -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos
                    $beforeIn = (Pmc-GetEditor).InCompletion
                    Write-PmcDebug -Level 2 -Category 'INPUT' -Message "Space key pressed: buffer='$((Pmc-GetEditor).Buffer)', cursor=$((Pmc-GetEditor).CursorPos), inCompletion=$((Pmc-GetEditor).InCompletion)"

                    if ((Pmc-GetEditor).InCompletion) {
                        # Accept current completion, add space, reset for next state
                        $selectedCompletion = (Pmc-GetEditor).Completions[(Pmc-GetEditor).CompletionIndex]
                        (Pmc-GetEditor).Buffer = Replace-TokenInBuffer -Buffer (Pmc-GetEditor).OriginalBuffer -TokenStart (Pmc-GetEditor).TokenStart -TokenEnd (Pmc-GetEditor).TokenEnd -Replacement $selectedCompletion

                        if (-not (Pmc-GetEditor).Buffer.EndsWith(' ')) {
                            (Pmc-GetEditor).Buffer += ' '
                        }
                        (Pmc-GetEditor).CursorPos = (Pmc-GetEditor).Buffer.Length

                        # Reset completion state
                        (Pmc-GetEditor).InCompletion = $false
                        (Pmc-GetEditor).Completions = @()
                        (Pmc-GetEditor).CompletionIndex = -1

                        # Get new context after state change for logging
                        $afterCtx = Parse-CompletionContext -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos

                        # Redraw and show ghost for next phase
                        Render-Interactive -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos -InCompletion $false

                        Write-PmcDebug -Level 2 -Category 'COMPLETION' -Message "Before Space accept: index=$((Pmc-GetEditor).CompletionIndex), selected item type=$($selectedCompletion.GetType().Name), text='$($selectedCompletion)'"
                        Write-PmcDebug -Level 2 -Category 'COMPLETION' -Message "After Space accept: new buffer='$((Pmc-GetEditor).Buffer)', phase=domain/action/prefix, nextState=$($afterCtx.Mode)"
                    } else {
                        # Insert space normally
                        (Pmc-GetEditor).Buffer = (Pmc-GetEditor).Buffer.Substring(0, (Pmc-GetEditor).CursorPos) + ' ' + (Pmc-GetEditor).Buffer.Substring((Pmc-GetEditor).CursorPos)
                        (Pmc-GetEditor).CursorPos++
                        Render-Interactive -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos -InCompletion $false
                    }
                    Write-StateChange -KeyName 'Space' -BeforeCtx $beforeCtx -BeforeInCompletion $beforeIn
                    continue
                }

                'Enter' {
                    $beforeCtx = Parse-CompletionContext -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos
                    $beforeIn = (Pmc-GetEditor).InCompletion
                    Write-PmcDebug -Level 2 -Category 'INPUT' -Message "Enter key pressed: buffer='$((Pmc-GetEditor).Buffer)', cursor=$((Pmc-GetEditor).CursorPos), inCompletion=$((Pmc-GetEditor).InCompletion)"

                    if ((Pmc-GetEditor).InCompletion) {
                        # Accept completion then submit
                        $selectedCompletion = (Pmc-GetEditor).Completions[(Pmc-GetEditor).CompletionIndex]
                        (Pmc-GetEditor).Buffer = Replace-TokenInBuffer -Buffer (Pmc-GetEditor).OriginalBuffer -TokenStart (Pmc-GetEditor).TokenStart -TokenEnd (Pmc-GetEditor).TokenEnd -Replacement $selectedCompletion
                        Write-PmcDebug -Level 2 -Category 'COMPLETION' -Message "Before Enter accept: index=$((Pmc-GetEditor).CompletionIndex), selected item type=$($selectedCompletion.GetType().Name), text='$($selectedCompletion)'"
                        Write-PmcDebug -Level 2 -Category 'COMPLETION' -Message "After Enter accept: final buffer='$((Pmc-GetEditor).Buffer)', phase=submit"
                    }

                    Clear-GhostText

                    if (-not [string]::IsNullOrWhiteSpace((Pmc-GetEditor).Buffer)) {
                        Add-ToHistory -Command (Pmc-GetEditor).Buffer
                    }

                    Write-StateChange -KeyName 'Enter' -BeforeCtx $beforeCtx -BeforeInCompletion $beforeIn
                    return (Pmc-GetEditor).Buffer
                }

                'Escape' {
                    $beforeCtx = Parse-CompletionContext -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos
                    $beforeIn = (Pmc-GetEditor).InCompletion
                    Write-PmcDebug -Level 2 -Category 'INPUT' -Message "Escape key pressed: buffer='$((Pmc-GetEditor).Buffer)', cursor=$((Pmc-GetEditor).CursorPos), inCompletion=$((Pmc-GetEditor).InCompletion)"

                    if ((Pmc-GetEditor).InCompletion) {
                        # Cancel completion, restore original buffer
                        (Pmc-GetEditor).Buffer = (Pmc-GetEditor).OriginalBuffer
                        (Pmc-GetEditor).CursorPos = (Pmc-GetEditor).OriginalBuffer.Length
                        (Pmc-GetEditor).InCompletion = $false
                        (Pmc-GetEditor).Completions = @()
                        (Pmc-GetEditor).CompletionIndex = -1
                        Render-Interactive -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos -InCompletion $false
                    } else {
                        # Clear entire line
                        (Pmc-GetEditor).Buffer = ""
                        (Pmc-GetEditor).CursorPos = 0
                        Render-Interactive -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos -InCompletion $false
                    }
                    Write-StateChange -KeyName 'Escape' -BeforeCtx $beforeCtx -BeforeInCompletion $beforeIn
                    continue
                }

                'Backspace' {
                    $beforeCtx = Parse-CompletionContext -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos
                    $beforeIn = (Pmc-GetEditor).InCompletion
                    Write-PmcDebug -Level 2 -Category 'INPUT' -Message "Backspace key pressed: buffer='$((Pmc-GetEditor).Buffer)', cursor=$((Pmc-GetEditor).CursorPos), inCompletion=$((Pmc-GetEditor).InCompletion)"
                    if ((Pmc-GetEditor).CursorPos -gt 0) {
                        (Pmc-GetEditor).Buffer = (Pmc-GetEditor).Buffer.Substring(0, (Pmc-GetEditor).CursorPos - 1) + (Pmc-GetEditor).Buffer.Substring((Pmc-GetEditor).CursorPos)
                        (Pmc-GetEditor).CursorPos--

                        # Exit completion mode when editing
                        if ((Pmc-GetEditor).InCompletion) {
                            (Pmc-GetEditor).InCompletion = $false
                            (Pmc-GetEditor).Completions = @()
                            (Pmc-GetEditor).CompletionIndex = -1
                        }

                        Render-Interactive -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos -InCompletion $false
                    }
                    Write-StateChange -KeyName 'Backspace' -BeforeCtx $beforeCtx -BeforeInCompletion $beforeIn
                    continue
                }

                'UpArrow' {
                    $beforeCtx = Parse-CompletionContext -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos
                    $beforeIn = (Pmc-GetEditor).InCompletion
                    Write-PmcDebug -Level 2 -Category 'INPUT' -Message "UpArrow key pressed: buffer='$((Pmc-GetEditor).Buffer)', historyIndex=$((Pmc-GetEditor).HistoryIndex), historySize=$((Pmc-GetEditor).History.Count)"

                    if ((Pmc-GetEditor).History.Count -gt 0) {
                        if ((Pmc-GetEditor).HistoryIndex -gt 0) { (Pmc-GetEditor).HistoryIndex-- }
                        (Pmc-GetEditor).Buffer = (Pmc-GetEditor).History[(Pmc-GetEditor).HistoryIndex]
                        (Pmc-GetEditor).CursorPos = (Pmc-GetEditor).Buffer.Length
                        (Pmc-GetEditor).InCompletion = $false
                        Render-Interactive -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos -InCompletion $false
                    }
                    Write-StateChange -KeyName 'UpArrow' -BeforeCtx $beforeCtx -BeforeInCompletion $beforeIn
                    continue
                }

                'DownArrow' {
                    $beforeCtx = Parse-CompletionContext -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos
                    $beforeIn = (Pmc-GetEditor).InCompletion
                    Write-PmcDebug -Level 2 -Category 'INPUT' -Message "DownArrow key pressed: buffer='$((Pmc-GetEditor).Buffer)', historyIndex=$((Pmc-GetEditor).HistoryIndex), historySize=$((Pmc-GetEditor).History.Count)"

                    if ((Pmc-GetEditor).History.Count -gt 0) {
                        if ((Pmc-GetEditor).HistoryIndex -lt ((Pmc-GetEditor).History.Count - 1)) {
                            (Pmc-GetEditor).HistoryIndex++
                            (Pmc-GetEditor).Buffer = (Pmc-GetEditor).History[(Pmc-GetEditor).HistoryIndex]
                        } else {
                            (Pmc-GetEditor).HistoryIndex = (Pmc-GetEditor).History.Count
                            (Pmc-GetEditor).Buffer = ""
                        }
                        (Pmc-GetEditor).CursorPos = (Pmc-GetEditor).Buffer.Length
                        (Pmc-GetEditor).InCompletion = $false
                        Render-Interactive -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos -InCompletion $false
                    }
                    Write-StateChange -KeyName 'DownArrow' -BeforeCtx $beforeCtx -BeforeInCompletion $beforeIn
                    continue
                }

                'R' {
                    if (($key.Modifiers -band [ConsoleModifiers]::Control) -ne 0) {
                        Write-PmcDebug -Level 2 -Category 'INPUT' -Message "Ctrl+R key pressed: reverse history search initiated, historySize=$((Pmc-GetEditor).History.Count)"

                        Write-Host "`r`e[0K(reverse-i-search): " -NoNewline
                        $searchTerm = ""
                    $searchResults = @()
                    $searchIndex = 0

                    while ($true) {
                        $searchKey = [Console]::ReadKey($true)

                        if ($searchKey.Key -eq 'Enter' -or $searchKey.Key -eq 'Escape') {
                            if ($searchKey.Key -eq 'Enter' -and $searchResults.Count -gt 0) {
                                (Pmc-GetEditor).Buffer = $searchResults[$searchIndex]
                                (Pmc-GetEditor).CursorPos = (Pmc-GetEditor).Buffer.Length
                            }
                            Render-Interactive -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos -InCompletion $false
                            break
                        } elseif ($searchKey.Key -eq 'Backspace' -and $searchTerm.Length -gt 0) {
                            $searchTerm = $searchTerm.Substring(0, $searchTerm.Length - 1)
                        } elseif ($searchKey.Key -eq 'R' -and $searchKey.Modifiers -eq 'Control') {
                            # Next search result
                            if ($searchResults.Count -gt 1) {
                                $searchIndex = ($searchIndex + 1) % $searchResults.Count
                            }
                        } elseif (-not [char]::IsControl($searchKey.KeyChar)) {
                            $searchTerm += $searchKey.KeyChar
                        }

                        # Update search results
                        if ($searchTerm.Length -gt 0) {
                            $searchResults = @((Pmc-GetEditor).History | Where-Object { $_ -like "*$searchTerm*" } | Select-Object -Last 10)
                            if ($searchResults.Count -eq 0) {
                                $searchResults = @()
                                $searchIndex = 0
                            } elseif ($searchIndex -ge $searchResults.Count) {
                                $searchIndex = 0
                            }
                        }

                        # Display search state
                        $displayText = if ($searchResults.Count -gt 0) { $searchResults[$searchIndex] } else { "" }
                        Write-Host "`r`e[0K(reverse-i-search)'$searchTerm': $displayText" -NoNewline
                    }

                        continue
                    } else {
                        # Regular 'R' character input
                        $editor = Pmc-GetEditor
                        $editor.Buffer = $editor.Buffer.Insert($editor.CursorPos, $key.KeyChar)
                        $editor.CursorPos++
                        Pmc-SetEditor $editor
                        Render-Interactive -Buffer $editor.Buffer -CursorPos $editor.CursorPos -InCompletion $false
                    }
                    continue
                }

                'Z' {
                    if (($key.Modifiers -band [ConsoleModifiers]::Control) -ne 0) {
                        Write-PmcDebug -Level 2 -Category 'INPUT' -Message "Ctrl+Z key pressed: undo, undoStackSize=$((Pmc-GetEditor).UndoStack.Count), redoStackSize=$((Pmc-GetEditor).RedoStack.Count)"

                        if ((Pmc-GetEditor).UndoStack.Count -gt 0) {
                            (Pmc-GetEditor).RedoStack += (Pmc-GetEditor).Buffer
                            (Pmc-GetEditor).Buffer = (Pmc-GetEditor).UndoStack[-1]
                            (Pmc-GetEditor).UndoStack = (Pmc-GetEditor).UndoStack[0..((Pmc-GetEditor).UndoStack.Count - 2)]
                            (Pmc-GetEditor).CursorPos = (Pmc-GetEditor).Buffer.Length
                            (Pmc-GetEditor).InCompletion = $false
                            Render-Interactive -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos -InCompletion $false
                        }
                        continue
                    } else {
                        # Regular 'Z' character input
                        (Pmc-GetEditor).Buffer = (Pmc-GetEditor).Buffer.Insert((Pmc-GetEditor).CursorPos, $key.KeyChar)
                        (Pmc-GetEditor).CursorPos++
                        Render-Interactive -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos -InCompletion $false
                    }
                    continue
                }

                'Y' {
                    if (($key.Modifiers -band [ConsoleModifiers]::Control) -ne 0) {
                        Write-PmcDebug -Level 2 -Category 'INPUT' -Message "Ctrl+Y key pressed: redo, undoStackSize=$((Pmc-GetEditor).UndoStack.Count), redoStackSize=$((Pmc-GetEditor).RedoStack.Count)"

                        if ((Pmc-GetEditor).RedoStack.Count -gt 0) {
                            (Pmc-GetEditor).UndoStack += (Pmc-GetEditor).Buffer
                            (Pmc-GetEditor).Buffer = (Pmc-GetEditor).RedoStack[-1]
                            (Pmc-GetEditor).RedoStack = (Pmc-GetEditor).RedoStack[0..((Pmc-GetEditor).RedoStack.Count - 2)]
                            (Pmc-GetEditor).CursorPos = (Pmc-GetEditor).Buffer.Length
                            (Pmc-GetEditor).InCompletion = $false
                            Render-Interactive -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos -InCompletion $false
                        }
                        continue
                    } else {
                        # Regular 'Y' character input
                        (Pmc-GetEditor).Buffer = (Pmc-GetEditor).Buffer.Insert((Pmc-GetEditor).CursorPos, $key.KeyChar)
                        (Pmc-GetEditor).CursorPos++
                        Render-Interactive -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos -InCompletion $false
                    }
                    continue
                }

                default {
                    $beforeCtx = Parse-CompletionContext -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos
                    $beforeIn = (Pmc-GetEditor).InCompletion
                    # Regular character input
                    if (-not [char]::IsControl($key.KeyChar)) {
                        # Character input reduced verbosity
                        # Exit completion mode when typing new characters
                        if ((Pmc-GetEditor).InCompletion) {
                            (Pmc-GetEditor).InCompletion = $false
                            (Pmc-GetEditor).Completions = @()
                            (Pmc-GetEditor).CompletionIndex = -1
                        }

                        (Pmc-GetEditor).Buffer = (Pmc-GetEditor).Buffer.Substring(0, (Pmc-GetEditor).CursorPos) + $key.KeyChar + (Pmc-GetEditor).Buffer.Substring((Pmc-GetEditor).CursorPos)
                        (Pmc-GetEditor).CursorPos++
                        Render-Interactive -Buffer (Pmc-GetEditor).Buffer -CursorPos (Pmc-GetEditor).CursorPos -InCompletion $false
                    }
                    Write-StateChange -KeyName 'Char' -BeforeCtx $beforeCtx -BeforeInCompletion $beforeIn
                    continue
                }
            }

        } catch {
            $snapshot = Get-EditorStateSnapshot
            Write-PmcDebug -Level 1 -Category 'INPUT' -Message "EXCEPTION: Input processing error: $_ | FULL STATE DUMP: $($snapshot | ConvertTo-Json -Depth 5 -Compress) | StackTrace: $($_.ScriptStackTrace)"
            Write-PmcDebug -Level 1 -Category 'INPUT' -Message "EXCEPTION CONTEXT: Key=$($key.Key), KeyChar='$($key.KeyChar)', Modifiers=$($key.Modifiers)"
            Write-PmcStyled -Style 'Error' -Text "Input processing failed: $_"
            break
        }
    }
}

# Initialize interactive mode
function Enable-PmcInteractiveMode {
    Write-PmcDebug -Level 1 -Category 'INTERACTIVE' -Message "Enabling PMC interactive mode with full t2.ps1 feature set"

    try {
        try { if (Get-Module PSReadLine -ErrorAction SilentlyContinue) { Remove-Module PSReadLine -Force -ErrorAction SilentlyContinue } } catch {}
        try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
        try { [Console]::CursorVisible = $true } catch {}
        # Clear completion cache
        Pmc-ClearCache

        # Initialize auxiliary completion info map (idempotent)
        $iMap = Pmc-GetInfoMap
        if (-not $iMap -or $iMap.Keys.Count -eq 0) {
            Initialize-PmcCompletionInfoMap
        }

        # Initialize editor state
        Pmc-SetEditor ([PmcEditorState]::new())

        Write-PmcStyled -Style 'Success' -Text "✓ Interactive mode enabled (Console.ReadKey)"
        return $true

    } catch {
        Write-PmcDebug -Level 1 -Category 'INTERACTIVE' -Message "Failed to enable interactive mode: $_"
        Write-PmcStyled -Style 'Error' -Text ("Failed to enable interactive mode: {0}" -f $_)
        return $false
    }
}

function Disable-PmcInteractiveMode {
    Write-PmcDebug -Level 1 -Category 'INTERACTIVE' -Message "Disabling PMC interactive mode"

    try {
        Pmc-ClearCache
        Pmc-SetEditor ([PmcEditorState]::new())
        Write-PmcStyled -Style 'Success' -Text "✓ Interactive mode disabled"

    } catch {
        Write-PmcDebug -Level 1 -Category 'INTERACTIVE' -Message "Error disabling interactive mode: $_"
        Write-PmcStyled -Style 'Error' -Text ("Error disabling interactive mode: {0}" -f $_)
    }
}

function Get-PmcInteractiveStatus {
    return @{
        Enabled = $true
        GhostTextEnabled = (Pmc-GetGhost)
        CacheSize = (Pmc-GetCache).Keys.Count
        HistorySize = (Pmc-GetEditor).History.Count
        UndoStackSize = (Pmc-GetEditor).UndoStack.Count
        Features = @("InlineCycling", "GhostText", "History", "CtrlR", "UndoRedo", "ErrorRecovery")
    }
}

# Export functions
Export-ModuleMember -Function Enable-PmcInteractiveMode, Disable-PmcInteractiveMode, Get-PmcInteractiveStatus, Read-PmcCommand, Pmc-InsertAtCursor


# END FILE: ./module/Pmc.Strict/src/Interactive.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/KanbanRenderer.ps1
# SIZE: 26.28 KB
# MODIFIED: 2025-09-22 17:43:07
# ================================================================================

# Kanban-style rendering system for grouped task and project views

Set-StrictMode -Version Latest

class PmcKanbanRenderer {
    [string] $Domain
    [string] $GroupField
    [hashtable] $Columns
    [object] $FrameRenderer
    [int] $SelectedLane = 0
    [int] $SelectedIndex = 0
    [array] $Lanes = @()  # array of @{ Key=<string>; Items=<array> }
    [object] $GridHelper
    [bool] $MoveActive = $false
    [int] $MoveSourceLane = -1
    [int] $MoveSourceIndex = -1
    [int] $MoveTargetLane = -1
    [int] $MoveTargetIndex = -1
    [array] $CurrentData = @()
    [int[]] $LaneOffsets = @()
    [bool] $ShowHelp = $false
    [string] $FilterText = ''
    [bool] $FilterActive = $false

    PmcKanbanRenderer([string]$domain, [string]$group, [hashtable]$columns) {
        $this.Domain = $domain
        $this.GroupField = $group
        $this.Columns = $columns
        $this.FrameRenderer = [PraxisFrameRenderer]::new()
        $this.GridHelper = [PmcGridRenderer]::new($columns, @($domain), @{})
    }

    [void] BuildLanes([array]$Data) {
        $map = @{}
        foreach ($row in $Data) {
            if ($null -eq $row) { continue }
            $key = ''
            try { if ($row.PSObject.Properties[$this.GroupField]) { $key = [string]$row.($this.GroupField) } } catch {}
            if (-not $map.ContainsKey($key)) { $map[$key] = @() }
            $map[$key] += $row
        }
        $keys = @($map.Keys | Sort-Object)
        $this.Lanes = @()
        foreach ($k in $keys) { $this.Lanes += @{ Key=$k; Items=$map[$k] } }
        # Preserve offsets by lane key
        $newOffsets = @()
        for ($i=0; $i -lt $this.Lanes.Count; $i++) {
            $key = $this.Lanes[$i].Key
            $off = 0
            if ($this.LaneOffsets -and $this.LaneOffsets.Count -eq $this.Lanes.Count) { $off = $this.LaneOffsets[$i] }
            $newOffsets += $off
        }
        $this.LaneOffsets = $newOffsets
        if ($this.SelectedLane -ge $this.Lanes.Count) { $this.SelectedLane = [Math]::Max(0, $this.Lanes.Count-1) }
        if ($this.SelectedLane -lt 0) { $this.SelectedLane = 0 }
        $currentCount = if ($this.Lanes.Count -gt 0) { @($this.Lanes[$this.SelectedLane].Items).Count } else { 0 }
        if ($this.SelectedIndex -ge $currentCount) { $this.SelectedIndex = [Math]::Max(0, $currentCount-1) }
        if ($this.SelectedIndex -lt 0) { $this.SelectedIndex = 0 }
        if (-not $this.MoveActive) { $this.MoveTargetLane = $this.SelectedLane; $this.MoveTargetIndex = $this.SelectedIndex }
    }

    [string] FormatCard([object]$item, [int]$width, [bool]$isSelected) {
        $id = ''
        if ($item -and $item.PSObject.Properties['id']) { $id = [string]$item.id }
        $text = $this.GridHelper.GetItemValue($item, 'text')
        $prio = $this.GridHelper.GetItemValue($item, 'priority')
        $due = $this.GridHelper.GetItemValue($item, 'due')
        $status = $this.GridHelper.GetItemValue($item, 'status')

        # Priority indicators with colors
        $prioIndicator = ''
        $prioColor = ''
        if ($prio) {
            try {
                $p = [int]$prio
                switch ($p) {
                    1 { $prioIndicator = '🔴'; $prioColor = 'Red' }
                    2 { $prioIndicator = '🟡'; $prioColor = 'Yellow' }
                    3 { $prioIndicator = '🟢'; $prioColor = 'Green' }
                    default { $prioIndicator = '●'; $prioColor = 'Gray' }
                }
            } catch {
                $prioIndicator = '●'; $prioColor = 'Gray'
            }
        }

        # Due date highlighting
        $dueIndicator = ''
        $dueColor = ''
        if ($due) {
            try {
                $dueDate = [datetime]$due
                $today = (Get-Date).Date
                $daysDiff = ($dueDate.Date - $today).Days
                if ($daysDiff -lt 0) {
                    $dueIndicator = '⚠️'; $dueColor = 'Red'  # Overdue
                } elseif ($daysDiff -eq 0) {
                    $dueIndicator = '⏰'; $dueColor = 'Yellow'  # Due today
                } elseif ($daysDiff -le 3) {
                    $dueIndicator = '📅'; $dueColor = 'Cyan'  # Due soon
                } else {
                    $dueIndicator = '📆'; $dueColor = 'Gray'  # Future
                }
            } catch {
                $dueIndicator = '📅'; $dueColor = 'Gray'
            }
        }

        # Status indicator
        $statusIndicator = ''
        if ($status) {
            switch ($status.ToLower()) {
                'done' { $statusIndicator = '✅' }
                'in progress' { $statusIndicator = '🔄' }
                'blocked' { $statusIndicator = '🚫' }
                'pending' { $statusIndicator = '⏳' }
                default { $statusIndicator = '📋' }
            }
        }

        # Build card content
        $indicators = @()
        if ($prioIndicator) { $indicators += $prioIndicator }
        if ($dueIndicator) { $indicators += $dueIndicator }
        if ($statusIndicator) { $indicators += $statusIndicator }

        $prefix = if ($indicators.Count -gt 0) { ($indicators -join '') + ' ' } else { '' }
        $idText = if ($id) { "#{0} " -f $id } else { '' }
        $mainText = $text

        # Calculate available space for text
        $prefixLen = ($prefix -replace '[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]', 'XX').Length
        $availableWidth = $width - $prefixLen - $idText.Length
        if ($mainText.Length -gt $availableWidth -and $availableWidth -gt 3) {
            $mainText = $mainText.Substring(0, $availableWidth - 1) + '…'
        }

        $label = $prefix + $idText + $mainText
        $label = $label.PadRight($width)

        if ($isSelected) {
            $style = Get-PmcStyle 'Selected'
            return $this.GridHelper.ConvertPmcStyleToAnsi($label, $style, @{})
        }

        # Apply priority-based coloring for non-selected cards
        if ($prioColor -and $prioColor -ne 'Gray') {
            try {
                $style = @{ ForegroundColor = $prioColor }
                return $this.GridHelper.ConvertPmcStyleToAnsi($label, $style, @{})
            } catch {
                return $label
            }
        }

        return $label
    }

    [string] BuildFrame() {
        return [PraxisStringBuilderPool]::Build({ param($sb)
            $termWidth = 100
            try { $termWidth = [PmcTerminalService]::GetWidth() } catch {}
            $laneCount = if ($this.Lanes.Count -gt 0) { $this.Lanes.Count } else { 1 }
            $gap = 3
            $totalGaps = ($laneCount - 1) * $gap
            $laneWidth = [Math]::Max(24, [Math]::Floor( ([double]$termWidth - $totalGaps - 2) / [Math]::Max(1,$laneCount) ))
            $termHeight = 25; try { $termHeight = [PmcTerminalService]::GetHeight() } catch {}
            $statusLines = 2
            $maxItemsPerLane = [Math]::Max(1, $termHeight - $statusLines - 2 - 2) # minus header & sep

            # Prepare lane content lines
            $laneLines = @()
            $maxLines = 0
            for ($i=0; $i -lt $laneCount; $i++) {
                $lane = $this.Lanes[$i]
                $lines = @()
                $isTarget = ($this.MoveActive -and $i -eq $this.MoveTargetLane)
                $itemCount = @($lane.Items).Count
                $header = ('{0} ({1})' -f ($lane.Key ?? '(none)'), $itemCount)
                if ($header.Length -gt $laneWidth) { $header = $header.Substring(0, [Math]::Max(0,$laneWidth-1)) + '…' }

                # Enhanced header styling for move mode
                if ($isTarget -and $this.MoveActive) {
                    $moveIndicator = '📥 '
                    $header = $moveIndicator + $header
                    if ($header.Length -gt $laneWidth) { $header = $header.Substring(0, [Math]::Max(0,$laneWidth-1)) + '…' }
                    $style = @{ BackgroundColor = 'DarkBlue'; ForegroundColor = 'White' }
                    $lines += $this.GridHelper.ConvertPmcStyleToAnsi($header.PadRight($laneWidth), $style, @{})
                } elseif ($this.MoveActive -and $i -eq $this.MoveSourceLane) {
                    $moveIndicator = '📤 '
                    $header = $moveIndicator + $header
                    if ($header.Length -gt $laneWidth) { $header = $header.Substring(0, [Math]::Max(0,$laneWidth-1)) + '…' }
                    $style = @{ BackgroundColor = 'DarkRed'; ForegroundColor = 'White' }
                    $lines += $this.GridHelper.ConvertPmcStyleToAnsi($header.PadRight($laneWidth), $style, @{})
                } elseif ($i -eq $this.SelectedLane -and -not $this.MoveActive) {
                    $style = Get-PmcStyle 'Selected'
                    $lines += $this.GridHelper.ConvertPmcStyleToAnsi($header.PadRight($laneWidth), $style, @{})
                } else {
                    $lines += $header.PadRight($laneWidth)
                }
                $lines += (('─' * [Math]::Max(1, $laneWidth)).Substring(0, $laneWidth))
                $idx = 0
                $offset = if ($this.LaneOffsets.Count -gt $i) { [Math]::Max(0, $this.LaneOffsets[$i]) } else { 0 }
                $visible = @($lane.Items | Select-Object -Skip $offset -First $maxItemsPerLane)
                foreach ($it in $visible) {
                    $isSel = ($i -eq $this.SelectedLane -and ($offset + $idx) -eq $this.SelectedIndex)
                    $isBeingMoved = ($this.MoveActive -and $i -eq $this.MoveSourceLane -and ($offset + $idx) -eq $this.MoveSourceIndex)
                    $isDropTarget = ($this.MoveActive -and $i -eq $this.MoveTargetLane -and ($offset + $idx) -eq $this.MoveTargetIndex)

                    if ($isBeingMoved) {
                        # Show card being moved with special styling
                        $cardText = $this.FormatCard($it, $laneWidth, $false)
                        $style = @{ BackgroundColor = 'DarkRed'; ForegroundColor = 'Yellow' }
                        $moveIndicator = '📦 MOVING → '
                        $cardText = $moveIndicator + $cardText.Trim()
                        if ($cardText.Length -gt $laneWidth) { $cardText = $cardText.Substring(0, [Math]::Max(0,$laneWidth-1)) + '…' }
                        $lines += $this.GridHelper.ConvertPmcStyleToAnsi($cardText.PadRight($laneWidth), $style, @{})
                    } elseif ($isDropTarget) {
                        # Show drop target position
                        $dropIndicator = '▼ DROP HERE ▼'
                        $style = @{ BackgroundColor = 'DarkGreen'; ForegroundColor = 'White' }
                        $lines += $this.GridHelper.ConvertPmcStyleToAnsi($dropIndicator.PadRight($laneWidth), $style, @{})
                        $lines += $this.FormatCard($it, $laneWidth, $isSel)
                    } else {
                        $lines += $this.FormatCard($it, $laneWidth, $isSel)
                    }
                    $idx++
                }

                # Add drop target at end of lane if target is beyond items
                if ($this.MoveActive -and $i -eq $this.MoveTargetLane -and $this.MoveTargetIndex -ge @($lane.Items).Count) {
                    $dropIndicator = '▼ DROP HERE ▼'
                    $style = @{ BackgroundColor = 'DarkGreen'; ForegroundColor = 'White' }
                    $lines += $this.GridHelper.ConvertPmcStyleToAnsi($dropIndicator.PadRight($laneWidth), $style, @{})
                }
                $laneLines += ,$lines
                if ($lines.Count -gt $maxLines) { $maxLines = $lines.Count }
            }

            # Compose lines row by row
            for ($row=0; $row -lt $maxLines; $row++) {
                $lineParts = @()
                for ($i=0; $i -lt $laneCount; $i++) {
                    $lines = $laneLines[$i]
                    $seg = if ($row -lt $lines.Count) { $lines[$row] } else { ''.PadRight($laneWidth) }
                    $lineParts += $seg
                }
                $sb.AppendLine(($lineParts -join (' ' * $gap))) | Out-Null
            }

            # Enhanced Status and Help
            $laneName = if ($this.Lanes.Count -gt 0) { $this.Lanes[$this.SelectedLane].Key } else { '' }
            $itemCount = if ($this.Lanes.Count -gt 0) { @($this.Lanes[$this.SelectedLane].Items).Count } else { 0 }

            $filterStatus = if ($this.FilterActive) { " | 🔍 Filter: '$($this.FilterText)'" } else { '' }

            if ($this.MoveActive) {
                $sourceLane = $this.Lanes[$this.MoveSourceLane].Key
                $targetLane = $this.Lanes[$this.MoveTargetLane].Key
                $status1 = ('🔄 MOVING from [{0}] to [{1}] | Position: {2}{3}' -f $sourceLane, $targetLane, ($this.MoveTargetIndex+1), $filterStatus)
                $status2 = ('📋 ←/→: change lane | ↑/↓: change position | Enter/Space: drop | Esc: cancel')
            } else {
                $selectedItem = if ($itemCount -gt 0 -and $this.SelectedIndex -lt $itemCount) {
                    $item = $this.Lanes[$this.SelectedLane].Items[$this.SelectedIndex]
                    $text = $this.GridHelper.GetItemValue($item, 'text')
                    if ($text.Length -gt 30) { $text.Substring(0, 27) + '...' } else { $text }
                } else { '' }

                $status1 = ('📂 LANE [{0}/{1}] {2} | ITEM [{3}/{4}] {5}{6}' -f ($this.SelectedLane+1), $laneCount, $laneName, ($this.SelectedIndex+1), $itemCount, $selectedItem, $filterStatus)
                $status2 = ('🎮 ←/→: lanes | ↑/↓: items | Space: move | Enter: drill down | /: filter | c: clear filter | ?/H: help | Q/Esc: exit')
            }

            $sb.AppendLine('') | Out-Null
            $sb.AppendLine($status1) | Out-Null
            $sb.Append($status2) | Out-Null
        })
    }

    [string] BuildHelpOverlay() {
        return [PraxisStringBuilderPool]::Build({ param($sb)
            $sb.AppendLine('╔═══════════════════════════════ KANBAN HELP ═══════════════════════════════╗') | Out-Null
            $sb.AppendLine('║                                                                           ║') | Out-Null
            $sb.AppendLine('║  NAVIGATION:                          ACTIONS:                           ║') | Out-Null
            $sb.AppendLine('║  ←/→  Navigate between lanes          Space    Start/complete move       ║') | Out-Null
            $sb.AppendLine('║  ↑/↓  Navigate between items          Enter    Drill down to item detail ║') | Out-Null
            $sb.AppendLine('║  PgUp/PgDn  Page through items        /        Filter cards by text      ║') | Out-Null
            $sb.AppendLine('║                                       c        Clear current filter      ║') | Out-Null
            $sb.AppendLine('║  VISUAL INDICATORS:                   r        Refresh view             ║') | Out-Null
            $sb.AppendLine('║  🔴🟡🟢  Priority (High/Med/Low)         ?/h      Show/hide this help      ║') | Out-Null
            $sb.AppendLine('║  ⚠️📅⏰   Due (Overdue/Soon/Today)        Q/Esc    Exit kanban view         ║') | Out-Null
            $sb.AppendLine('║  ✅🔄🚫   Status (Done/Progress/Block)                                    ║') | Out-Null
            $sb.AppendLine('║  📥📤     Move target/source lanes                                       ║') | Out-Null
            $sb.AppendLine('║                                                                           ║') | Out-Null
            $sb.AppendLine('║  MOVE MODE: Select item → Space → Navigate to target → Enter/Space      ║') | Out-Null
            $sb.AppendLine('║                                                                           ║') | Out-Null
            $sb.AppendLine('╚═══════════════════════════════════════════════════════════════════════════╝') | Out-Null
            $sb.AppendLine('') | Out-Null
            $sb.Append('Press any key to continue...') | Out-Null
        })
    }

    [void] StartInteractive([array]$Data) {
        $this.CurrentData = $Data
        $this.BuildLanes($Data)
        $refresh = $true
        while ($true) {
            if ($refresh) {
                if ($this.ShowHelp) {
                    $content = $this.BuildHelpOverlay()
                } else {
                    $content = $this.BuildFrame()
                }
                $this.FrameRenderer.RenderFrame($content)
                $refresh = $false
            }
            if ([Console]::KeyAvailable) {
                $k = [Console]::ReadKey($true)

                # Handle help overlay
                if ($this.ShowHelp) {
                    $this.ShowHelp = $false
                    $refresh = $true
                    continue
                }

                switch ($k.Key) {
                    'LeftArrow'  {
                        if ($this.MoveActive) { if ($this.MoveTargetLane -gt 0) { $this.MoveTargetLane--; $refresh=$true } }
                        else { if ($this.SelectedLane -gt 0) { $this.SelectedLane--; $this.SelectedIndex = 0; $refresh=$true } }
                    }
                    'RightArrow' {
                        if ($this.MoveActive) { if ($this.MoveTargetLane -lt ($this.Lanes.Count-1)) { $this.MoveTargetLane++; $refresh=$true } }
                        else { if ($this.SelectedLane -lt ($this.Lanes.Count-1)) { $this.SelectedLane++; $this.SelectedIndex = 0; $refresh=$true } }
                    }
                    'UpArrow'    {
                        $cnt = @($this.Lanes[$this.SelectedLane].Items).Count
                        if ($this.SelectedIndex -gt 0) { $this.SelectedIndex-- }
                        # adjust offset
                        $off = $this.LaneOffsets[$this.SelectedLane]
                        if ($this.SelectedIndex -lt $off) { $this.LaneOffsets[$this.SelectedLane] = [Math]::Max(0, $off-1) }
                        if ($this.MoveActive) { $this.MoveTargetLane = $this.SelectedLane; $this.MoveTargetIndex = $this.SelectedIndex }
                        $refresh=$true
                    }
                    'DownArrow'  {
                        $cnt = @($this.Lanes[$this.SelectedLane].Items).Count
                        if ($this.SelectedIndex -lt ($cnt-1)) { $this.SelectedIndex++ }
                        $off = $this.LaneOffsets[$this.SelectedLane]
                        $termHeight = 25; try { $termHeight = [PmcTerminalService]::GetHeight() } catch {}
                        $maxItemsPerLane = [Math]::Max(1, $termHeight - 2 - 2 - 2)
                        if ($this.SelectedIndex -ge ($off + $maxItemsPerLane)) { $this.LaneOffsets[$this.SelectedLane] = $off + 1 }
                        if ($this.MoveActive) { $this.MoveTargetLane = $this.SelectedLane; $this.MoveTargetIndex = $this.SelectedIndex }
                        $refresh=$true
                    }
                    'PageUp'     {
                        $off = $this.LaneOffsets[$this.SelectedLane]
                        $termHeight = 25; try { $termHeight = [PmcTerminalService]::GetHeight() } catch {}
                        $maxItemsPerLane = [Math]::Max(1, $termHeight - 2 - 2 - 2)
                        $this.LaneOffsets[$this.SelectedLane] = [Math]::Max(0, $off - $maxItemsPerLane)
                        $this.SelectedIndex = [Math]::Max(0, $this.SelectedIndex - $maxItemsPerLane)
                        if ($this.MoveActive) { $this.MoveTargetLane = $this.SelectedLane; $this.MoveTargetIndex = $this.SelectedIndex }
                        $refresh=$true
                    }
                    'PageDown'   {
                        $off = $this.LaneOffsets[$this.SelectedLane]
                        $termHeight = 25; try { $termHeight = [PmcTerminalService]::GetHeight() } catch {}
                        $maxItemsPerLane = [Math]::Max(1, $termHeight - 2 - 2 - 2)
                        $this.LaneOffsets[$this.SelectedLane] = $off + $maxItemsPerLane
                        $this.SelectedIndex = $this.SelectedIndex + $maxItemsPerLane
                        if ($this.MoveActive) { $this.MoveTargetLane = $this.SelectedLane; $this.MoveTargetIndex = $this.SelectedIndex }
                        $refresh=$true
                    }
                    'Spacebar'   {
                        if (-not $this.MoveActive) {
                            $this.MoveActive = $true
                            $this.MoveSourceLane = $this.SelectedLane
                            $this.MoveSourceIndex = $this.SelectedIndex
                            $this.MoveTargetLane = $this.SelectedLane
                            $refresh = $true
                        } else {
                            # Drop
                            $this.ApplyMove()
                            $refresh = $true
                        }
                    }
                    'Enter'      {
                        if ($this.MoveActive) { $this.ApplyMove(); $refresh=$true }
                        else {
                            try {
                                $lane = $this.Lanes[$this.SelectedLane]
                                if ($lane) {
                                    Show-PmcCustomGrid -Domain $this.Domain -Columns $this.Columns -Data $lane.Items -Interactive
                                    $this.BuildLanes($this.CurrentData)
                                    $refresh = $true
                                }
                            } catch {}
                        }
                    }
                    'Escape'     { if ($this.MoveActive) { $this.MoveActive=$false; $refresh=$true } else { break } }
                    'Q' { break }
                    'H' { $this.ShowHelp = $true; $refresh = $true }
                    'R' { $this.BuildLanes($this.CurrentData); $refresh = $true }
                    'C' { $this.FilterText = ''; $this.FilterActive = $false; $this.BuildLanes($this.CurrentData); $refresh = $true }
                    default {
                        # Handle special characters
                        if ($k.KeyChar -eq '?') { $this.ShowHelp = $true; $refresh = $true }
                        elseif ($k.KeyChar -eq '/') { $this.StartFilter(); $refresh = $true }
                    }
                }
            } else {
                Start-Sleep -Milliseconds 50
            }
        }
    }

    [void] ApplyMove() {
        if (-not $this.MoveActive) { return }
        try {
            $srcLane = $this.Lanes[$this.MoveSourceLane]
            if (-not $srcLane) { $this.MoveActive=$false; return }
            $item = $srcLane.Items[$this.MoveSourceIndex]
            if (-not $item) { $this.MoveActive=$false; return }
            $targetLane = $this.Lanes[$this.MoveTargetLane]
            $newKey = [string]($targetLane.Key)

            # Only support task domain for move in MVP
            if ($this.Domain -ne 'task') { $this.MoveActive=$false; return }
            $field = $this.GroupField
            if ([string]::IsNullOrWhiteSpace($field)) { $this.MoveActive=$false; return }

            # Update persistent store
            $root = Get-PmcDataAlias
            $id = if ($item.PSObject.Properties['id']) { [int]$item.id } else { -1 }
            if ($id -lt 0) { $this.MoveActive=$false; return }
            $target = $root.tasks | Where-Object { $_ -ne $null -and $_.PSObject.Properties['id'] -and [int]$_.id -eq $id } | Select-Object -First 1
            if (-not $target) { $this.MoveActive=$false; return }

            $val = $newKey
            if ($field -eq 'project' -and [string]::IsNullOrWhiteSpace($val)) { $val = 'inbox' }
            if ($target.PSObject.Properties[$field]) { $target.$field = $val } else { Add-Member -InputObject $target -MemberType NoteProperty -Name $field -NotePropertyValue $val -Force }
            Save-PmcData -data $root -Action ("kanban-move:$field")

            # Reflect change in live item
            if ($item.PSObject.Properties[$field]) { $item.$field = $val } else { Add-Member -InputObject $item -MemberType NoteProperty -Name $field -NotePropertyValue $val -Force }

            # Reorder in current data to reflect new position (ephemeral)
            $list = New-Object System.Collections.ArrayList
            foreach ($x in $this.CurrentData) { [void]$list.Add($x) }
            $oldIdx = $list.IndexOf($item)
            if ($oldIdx -ge 0) { $list.RemoveAt($oldIdx) }
            # Find insertion index: before MoveTargetIndex in target lane sequence
            $flat = @()
            foreach ($ln in $this.Lanes) { foreach ($it in $ln.Items) { $flat += $it } }
            # Build new lanes based on updated field
            $this.BuildLanes(@($list))
            $tItems = @($this.Lanes[$this.MoveTargetLane].Items)
            $insertRef = if ($this.MoveTargetIndex -ge 0 -and $this.MoveTargetIndex -lt $tItems.Count) { $tItems[$this.MoveTargetIndex] } else { $null }
            $insIdx = if ($insertRef) { $list.IndexOf($insertRef) } else { $list.Count }
            if ($insIdx -lt 0) { $insIdx = $list.Count }
            $list.Insert($insIdx, $item)

            $this.CurrentData = @($list)
            $this.BuildLanes($this.CurrentData)
            $this.SelectedLane = $this.MoveTargetLane; $this.SelectedIndex = $this.MoveTargetIndex
        } catch {
            # Ignore, fail-safe
        } finally {
            $this.MoveActive = $false
            $this.MoveSourceLane = -1
            $this.MoveSourceIndex = -1
            $this.MoveTargetIndex = -1
        }
    }

    [void] StartFilter() {
        Write-Host "`r`e[2KFilter: " -NoNewline
        $filter = Read-Host
        if (-not [string]::IsNullOrWhiteSpace($filter)) {
            $this.FilterText = $filter.Trim()
            $this.FilterActive = $true
            $this.ApplyFilter()
        }
    }

    [void] ApplyFilter() {
        if ($this.FilterActive -and -not [string]::IsNullOrWhiteSpace($this.FilterText)) {
            $filteredData = @()
            foreach ($item in $this.CurrentData) {
                if ($null -eq $item) { continue }
                $text = $this.GridHelper.GetItemValue($item, 'text')
                $id = if ($item.PSObject.Properties['id']) { [string]$item.id } else { '' }
                if ($text.ToLower().Contains($this.FilterText.ToLower()) -or $id.Contains($this.FilterText)) {
                    $filteredData += $item
                }
            }
            $this.BuildLanes($filteredData)
        } else {
            $this.BuildLanes($this.CurrentData)
        }
    }
}


# END FILE: ./module/Pmc.Strict/src/KanbanRenderer.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/PraxisFrameRenderer.ps1
# SIZE: 6.96 KB
# MODIFIED: 2025-09-22 17:43:07
# ================================================================================

# Frame-based rendering system - stolen from Praxis ScreenManager and adapted for PMC

class PraxisFrameRenderer {
    # Double buffering
    hidden [string]$_lastFrame = ""
    hidden [bool]$_needsRender = $true
    hidden [int]$_frameCount = 0

    # Performance tracking
    hidden [System.Diagnostics.Stopwatch]$_renderTimer
    hidden [double]$_lastRenderTime = 0

    PraxisFrameRenderer() {
        $this._renderTimer = [System.Diagnostics.Stopwatch]::new()
    }

    # Main render method - stolen from Praxis ScreenManager
    [void] RenderFrame([string]$content) {
        $this._renderTimer.Restart()

        # Only render if content changed (Praxis optimization)
        if ($this._lastFrame -ne $content -or $this._needsRender) {

            # Clear screen only on first render or significant changes
            if ($this._lastFrame -eq "" -or $this._frameCount -eq 0) {
                [Console]::Write([PraxisVT]::Clear())
            }

            # Single atomic write - the Praxis way
            [Console]::CursorVisible = $false
            [Console]::SetCursorPosition(0, 0)
            [Console]::Write($content)

            # Store for next comparison
            $this._lastFrame = $content
            $this._needsRender = $false
        }

        $this._renderTimer.Stop()
        $this._frameCount++
        $this._lastRenderTime = $this._renderTimer.ElapsedMilliseconds
    }

    # Force next render (for resize, data changes, etc.)
    [void] Invalidate() {
        $this._needsRender = $true
        $this._lastFrame = ""  # Force full redraw
    }

    # Get performance info
    [hashtable] GetStats() {
        return @{
            FrameCount = $this._frameCount
            LastRenderTime = $this._lastRenderTime
            NeedsRender = $this._needsRender
        }
    }
}

# Grid frame builder - adapts Praxis CleanRender concepts for PMC grids
class PraxisGridFrameBuilder {
    static [string] BuildGridFrame([array]$data, [hashtable]$columns, [string]$title, [int]$selectedRow, [hashtable]$theme, [object]$renderer) {
        return [PraxisStringBuilderPool]::Build({
            param($sb)

            # Title
            if ($title) {
                $sb.AppendLine($title)
                $sb.AppendLine("─" * 50)  # Simple separator
            }

            # Use PMC's intelligent column width calculation
            $widths = $renderer.GetColumnWidths($data)

            # Column headers
            $headerParts = @()
            $separatorParts = @()
            $colNames = @($columns.Keys)
            foreach ($col in $colNames) {
                $config = $columns[$col]
                $width = $widths[$col]
                $header = $col
                if ($config -and $config.PSObject.Properties['Header'] -and $config.Header) { $header = $config.Header }

                $headerParts += [PraxisMeasure]::Pad($header, $width, "Left")
                $separatorParts += "─" * $width
            }
            $sb.AppendLine(($headerParts -join "  "))
            $sb.AppendLine(($separatorParts -join "  "))

            # Data rows
            for ($i = 0; $i -lt $data.Count; $i++) {
                $item = $data[$i]
                $isSelected = ($i -eq $selectedRow)
                $prefix = " "
                if ($isSelected) { $prefix = "►" }

                $rowParts = @()
                foreach ($col in $colNames) {
                    $width = $widths[$col]
                    # Prefer renderer's item value logic
                    $value = $renderer.GetItemValue($item, $col)
                    # If selected row is being actively edited, show live EditingValue
                    if ($isSelected -and $renderer.InlineEditMode -and $renderer.EditingColumn -eq $col) {
                        $value = [string]$renderer.EditingValue
                    }
                    # Otherwise, if selected row has a staged edit, show it
                    elseif ($isSelected -and $renderer.PendingEdits.ContainsKey($col)) {
                        $value = [string]$renderer.PendingEdits[$col]
                    }

                    # Show inline edit mode with background highlight (themeable)
                    $padded = [PraxisMeasure]::Pad($value, $width, "Left")
                    if ($isSelected -and $renderer.InlineEditMode -and $renderer.EditingColumn -eq $col) {
                        $editStyle = Get-PmcStyle 'Editing'
                        $padded = $renderer.ConvertPmcStyleToAnsi($padded, $editStyle, @{})
                    } elseif ($isSelected) {
                        # Apply selection highlight
                        $applyCell = $true
                        if ($renderer.NavigationMode -eq 'Cell') {
                            # Only highlight the selected column in Cell mode
                            $selIdx = [Math]::Min($colNames.Count-1, [Math]::Max(0, $renderer.SelectedColumn))
                            if ($col -ne $colNames[$selIdx]) { $applyCell = $false }
                        }
                        if ($applyCell) {
                            $selStyle = Get-PmcStyle 'Selected'
                            $padded = $renderer.ConvertPmcStyleToAnsi($padded, $selStyle, @{})
                        }
                    }
                    $rowParts += $padded
                }

                $sb.Append($prefix)
                $sb.AppendLine(($rowParts -join "  "))
            }

            # Status line (move to bottom)
            $consoleHeight = [PmcTerminalService]::GetHeight()
            $currentLine = $data.Count + 5  # Approximate current line
            $bottomLine = $consoleHeight - 1

            # Determine footer lines: optional error, optional hint, plus status
            $footerCount = 1
            $hasError = ($renderer.LastErrorMessage -and $renderer.LastErrorMessage.Length -gt 0)
            $hasHint = $renderer.InlineEditMode
            if ($hasError) { $footerCount++ }
            if ($hasHint) { $footerCount++ }

            if ($currentLine -lt $bottomLine) {
                # Add spacing to push footers to bottom
                $spacingNeeded = $bottomLine - $currentLine - $footerCount
                for ($i = 0; $i -lt $spacingNeeded; $i++) { $sb.AppendLine("") }
            }

            # Error line (highlighted)
            if ($hasError) {
                $err = $renderer.StyleText('Error', ("ERROR: {0}" -f $renderer.LastErrorMessage))
                $sb.AppendLine($err)
            }

            # Hint line during editing
            if ($hasHint) {
                $col = $renderer.EditingColumn
                $hint = $renderer.GetFieldHint($col)
                if (-not $hint) { $hint = 'Enter: Save, Esc: Cancel, Tab: Next, Shift+Tab: Prev' }
                $hintLine = $renderer.StyleText('Info', ("Editing {0} — {1}" -f $col, $hint))
                $sb.AppendLine($hintLine)
            }

            # Status line
            $statusText = "ROW [$($selectedRow + 1)/$($data.Count)] | Arrow keys: Navigate | Enter: Edit | Q: Exit"
            $sb.Append($statusText)
        })
    }
}


# END FILE: ./module/Pmc.Strict/src/PraxisFrameRenderer.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/PraxisStringBuilder.ps1
# SIZE: 1.6 KB
# MODIFIED: 2025-09-22 15:23:10
# ================================================================================

# StringBuilder pooling system - stolen directly from Praxis

class PraxisStringBuilderPool {
    static [System.Collections.Generic.Queue[System.Text.StringBuilder]]$_pool = [System.Collections.Generic.Queue[System.Text.StringBuilder]]::new()
    static [int]$_maxPoolSize = 20
    static [int]$_defaultCapacity = 1024

    static [System.Text.StringBuilder] Get([int]$initialCapacity = 1024) {
        if ([PraxisStringBuilderPool]::_pool.Count -gt 0) {
            $sb = [PraxisStringBuilderPool]::_pool.Dequeue()
            $sb.Clear()
            if ($sb.Capacity -lt $initialCapacity) {
                $sb.Capacity = $initialCapacity
            }
            return $sb
        }
        return [System.Text.StringBuilder]::new($initialCapacity)
    }

    static [void] Return([System.Text.StringBuilder]$sb) {
        if ($sb -and [PraxisStringBuilderPool]::_pool.Count -lt [PraxisStringBuilderPool]::_maxPoolSize) {
            $sb.Clear()
            [PraxisStringBuilderPool]::_pool.Enqueue($sb)
        }
    }

    static [string] Build([scriptblock]$buildAction) {
        $sb = [PraxisStringBuilderPool]::Get(1024)
        try {
            & $buildAction $sb
            return $sb.ToString()
        } finally {
            [PraxisStringBuilderPool]::Return($sb)
        }
    }
}

# Convenience functions
function Get-PooledStringBuilder([int]$capacity = 1024) {
    return [PraxisStringBuilderPool]::Get($capacity)
}

function Return-PooledStringBuilder([System.Text.StringBuilder]$sb) {
    [PraxisStringBuilderPool]::Return($sb)
}

#Export-ModuleMember -Function Get-PooledStringBuilder, Return-PooledStringBuilder

# END FILE: ./module/Pmc.Strict/src/PraxisStringBuilder.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/PraxisVT.ps1
# SIZE: 4.27 KB
# MODIFIED: 2025-09-22 15:23:10
# ================================================================================

# VT100/ANSI Core - Stolen directly from Praxis with minimal changes for PMC

class PraxisVT {
    # Cursor movement
    static [string] MoveTo([int]$x, [int]$y) {
        return "`e[$($y+1);$($x+1)H"  # Convert 0-based to 1-based for ANSI
    }
    static [string] SavePos() { return "`e[s" }
    static [string] RestorePos() { return "`e[u" }

    # Cursor visibility
    static [string] Hide() { return "`e[?25l" }
    static [string] Show() { return "`e[?25h" }
    static [string] HideCursor() { return "`e[?25l" }
    static [string] ShowCursor() { return "`e[?25h" }

    # Cursor movement methods
    static [string] MoveUp([int]$n) { return "`e[$($n)A" }
    static [string] MoveDown([int]$n) { return "`e[$($n)B" }
    static [string] MoveRight([int]$n) { return "`e[$($n)C" }
    static [string] MoveLeft([int]$n) { return "`e[$($n)D" }

    # Screen control
    static [string] Clear() { return "`e[2J`e[H" }  # Clear screen and home
    static [string] ClearLine() { return "`e[2K" }  # Clear entire line
    static [string] Home() { return "`e[H" }      # Just home position
    static [string] ClearToEnd() { return "`e[J" }  # Clear from cursor to end

    # Basic styles
    static [string] Reset() { return "`e[0m" }
    static [string] Bold() { return "`e[1m" }
    static [string] Dim() { return "`e[2m" }
    static [string] Italic() { return "`e[3m" }
    static [string] Underline() { return "`e[4m" }
    static [string] NoUnderline() { return "`e[24m" }

    # 24-bit True Color
    static [string] RGB([int]$r, [int]$g, [int]$b) {
        return "`e[38;2;$r;$g;$($b)m"
    }
    static [string] RGBBG([int]$r, [int]$g, [int]$b) {
        return "`e[48;2;$r;$g;$($b)m"
    }

    # 256-color support
    static [string] Color256Fg([int]$color) {
        return "`e[38;5;$($color)m"
    }
    static [string] Color256Bg([int]$color) {
        return "`e[48;5;$($color)m"
    }

    # Box drawing - single lines for speed
    static [string] TL() { return "┌" }     # Top left
    static [string] TR() { return "┐" }     # Top right
    static [string] BL() { return "└" }     # Bottom left
    static [string] BR() { return "┘" }     # Bottom right
    static [string] H() { return "─" }      # Horizontal
    static [string] V() { return "│" }      # Vertical
    static [string] Cross() { return "┼" }  # Cross
    static [string] T() { return "┬" }      # T down
    static [string] B() { return "┴" }      # T up
    static [string] L() { return "├" }      # T right
    static [string] R() { return "┤" }      # T left
}

# Layout measurement helpers - stolen from Praxis
class PraxisMeasure {
    static [int] TextWidth([string]$text) {
        # Remove ANSI sequences for accurate measurement
        $clean = $text -replace '\x1b\[[0-9;]*m', ''
        return $clean.Length
    }

    static [string] Truncate([string]$text, [int]$maxWidth) {
        $clean = $text -replace '\x1b\[[0-9;]*m', ''
        if ($clean.Length -le $maxWidth) { return $text }
        return $clean.Substring(0, $maxWidth - 3) + "..."
    }

    static [string] Pad([string]$text, [int]$width, [string]$align = "Left") {
        $textWidth = [PraxisMeasure]::TextWidth($text)
        if ($textWidth -ge $width) { return [PraxisMeasure]::Truncate($text, $width) }

        $padding = $width - $textWidth
        switch ($align) {
            "Left" { return $text + (' ' * $padding) }
            "Right" { return (' ' * $padding) + $text }
            "Center" {
                $left = [int]($padding / 2)
                $right = $padding - $left
                return (' ' * $left) + $text + (' ' * $right)
            }
        }
        return $text
    }
}

# String cache for performance - stolen from Praxis
class PraxisStringCache {
    static [hashtable]$_cache = @{}

    static [string] GetSpaces([int]$count) {
        if ($count -le 0) { return "" }
        if (-not [PraxisStringCache]::_cache.ContainsKey($count)) {
            [PraxisStringCache]::_cache[$count] = ' ' * $count
        }
        return [PraxisStringCache]::_cache[$count]
    }

    static [string] GetChar([char]$c, [int]$count) {
        $key = "$c-$count"
        if (-not [PraxisStringCache]::_cache.ContainsKey($key)) {
            [PraxisStringCache]::_cache[$key] = [string]$c * $count
        }
        return [PraxisStringCache]::_cache[$key]
    }
}

# END FILE: ./module/Pmc.Strict/src/PraxisVT.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/Projects.ps1
# SIZE: 11.73 KB
# MODIFIED: 2025-09-22 15:23:10
# ================================================================================

# Projects.ps1 - Project management functions
# Core project CRUD operations for PMC

function Add-PmcProject {
    param([PmcCommandContext]$Context)

    # If no arguments provided, launch the full wizard
    if (-not $Context -or $Context.FreeText.Count -eq 0) {
        Write-PmcStyled -Style 'Info' -Text "Launching Project Creation Wizard..."
        Start-PmcProjectWizard -Context $Context
        return
    }

    # If arguments provided, do quick project creation
    $projectName = $Context.FreeText[0]
    $description = if ($Context.FreeText.Count -gt 1) { ($Context.FreeText[1..($Context.FreeText.Count-1)] -join ' ') } else { "" }

    try {
        # Load existing data
        $allData = Get-PmcAllData

        # Check if project already exists
        $existing = $allData.projects | Where-Object { $_.name -eq $projectName }
        if ($existing) {
            Write-PmcStyled -Style 'Error' -Text "Project '$projectName' already exists"
            return
        }

        # Create new project
        $newProject = @{
            id = [guid]::NewGuid().ToString()
            name = $projectName
            description = $description
            created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            status = 'active'
            tags = @()
        }

        # Add to data
        if (-not $allData.projects) { $allData.projects = @() }
        $allData.projects += $newProject

        # Save data
        Set-PmcAllData $allData

        Write-PmcStyled -Style 'Success' -Text "✓ Project '$projectName' created"

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error creating project: $_"
    }
}

function Show-PmcProject {
    param([PmcCommandContext]$Context)

    if (-not $Context -or $Context.FreeText.Count -eq 0) {
        Write-PmcStyled -Style 'Error' -Text "Usage: project view <name>"
        return
    }

    $projectName = $Context.FreeText[0]

    try {
        $allData = Get-PmcAllData
        $project = $allData.projects | Where-Object { $_.name -eq $projectName }

        if (-not $project) {
            Write-PmcStyled -Style 'Error' -Text "Project '$projectName' not found"
            return
        }

        Write-PmcStyled -Style 'Header' -Text "`nProject: $($project.name)"
        Write-PmcStyled -Style 'Body' -Text "Description: $($project.description)"
        Write-PmcStyled -Style 'Body' -Text "Created: $($project.created)"
        Write-PmcStyled -Style 'Body' -Text "Status: $($project.status)"

        # Show related tasks
        $tasks = $allData.tasks | Where-Object { $_.project -eq $projectName }
        if ($tasks) {
            Write-PmcStyled -Style 'Header' -Text "`nTasks:"
            foreach ($task in $tasks) {
                $status = if ($task.completed) { "✓" } else { "○" }
                Write-PmcStyled -Style 'Body' -Text "  $status $($task.text)"
            }
        }

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error viewing project: $_"
    }
}

function Set-PmcProject {
    param([PmcCommandContext]$Context)

    if (-not $Context -or $Context.FreeText.Count -lt 2) {
        Write-PmcStyled -Style 'Error' -Text "Usage: project update <name> <field> <value>"
        return
    }

    $projectName = $Context.FreeText[0]
    $field = $Context.FreeText[1]
    $value = if ($Context.FreeText.Count -gt 2) { ($Context.FreeText[2..($Context.FreeText.Count-1)] -join ' ') } else { "" }

    try {
        $allData = Get-PmcAllData
        $project = $allData.projects | Where-Object { $_.name -eq $projectName }

        if (-not $project) {
            Write-PmcStyled -Style 'Error' -Text "Project '$projectName' not found"
            return
        }

        switch ($field.ToLower()) {
            'description' { $project.description = $value }
            'status' { $project.status = $value }
            default {
                Write-PmcStyled -Style 'Error' -Text "Unknown field '$field'. Available: description, status"
                return
            }
        }

        Set-PmcAllData $allData
        Write-PmcStyled -Style 'Success' -Text "✓ Project '$projectName' updated"

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error updating project: $_"
    }
}

function Edit-PmcProject {
    param([PmcCommandContext]$Context)

    if (-not $Context -or $Context.FreeText.Count -eq 0) {
        Write-PmcStyled -Style 'Error' -Text "Usage: project edit <name>"
        return
    }

    $projectName = $Context.FreeText[0]

    try {
        $allData = Get-PmcAllData
        $project = $allData.projects | Where-Object { $_.name -eq $projectName }

        if (-not $project) {
            Write-PmcStyled -Style 'Error' -Text "Project '$projectName' not found"
            return
        }

        # Create editable project data
        $editableProject = [pscustomobject]@{
            Name = $project.name
            Description = $project.description
            Status = $project.status
        }

        $columns = @{
            Name = @{ Header='Project Name'; Width=25; Alignment='Left'; Editable=$true }
            Description = @{ Header='Description'; Width=45; Alignment='Left'; Editable=$true }
            Status = @{ Header='Status'; Width=15; Alignment='Left'; Editable=$true }
        }

        Write-PmcStyled -Style 'Info' -Text "Edit project details. Press Enter to save changes, Q to finish."

        Show-PmcDataGrid -Domains @('project-edit') -Columns $columns -Data @($editableProject) -Title "Edit Project: $projectName" -Interactive -OnSelectCallback {
            param($item)
            if ($item) {
                # Update project with edited values
                $project.name = [string]$item.Name
                $project.description = [string]$item.Description
                $project.status = [string]$item.Status

                Set-PmcAllData $allData
                Write-PmcStyled -Style 'Success' -Text "✓ Project '$projectName' updated"
            }
        }

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error editing project: $_"
    }
}

function Rename-PmcProject {
    param([PmcCommandContext]$Context)

    if (-not $Context -or $Context.FreeText.Count -lt 2) {
        Write-PmcStyled -Style 'Error' -Text "Usage: project rename <old-name> <new-name>"
        return
    }

    $oldName = $Context.FreeText[0]
    $newName = $Context.FreeText[1]

    try {
        $allData = Get-PmcAllData
        $project = $allData.projects | Where-Object { $_.name -eq $oldName }

        if (-not $project) {
            Write-PmcStyled -Style 'Error' -Text "Project '$oldName' not found"
            return
        }

        # Check if new name already exists
        $existing = $allData.projects | Where-Object { $_.name -eq $newName }
        if ($existing) {
            Write-PmcStyled -Style 'Error' -Text "Project '$newName' already exists"
            return
        }

        # Update project name
        $project.name = $newName

        # Update all tasks with this project
        $allData.tasks | Where-Object { $_.project -eq $oldName } | ForEach-Object { $_.project = $newName }

        Set-PmcAllData $allData
        Write-PmcStyled -Style 'Success' -Text "✓ Project renamed from '$oldName' to '$newName'"

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error renaming project: $_"
    }
}

function Remove-PmcProject {
    param([PmcCommandContext]$Context)

    if (-not $Context -or $Context.FreeText.Count -eq 0) {
        Write-PmcStyled -Style 'Error' -Text "Usage: project remove <name>"
        return
    }

    $projectName = $Context.FreeText[0]

    try {
        $allData = Get-PmcAllData
        $project = $allData.projects | Where-Object { $_.name -eq $projectName }

        if (-not $project) {
            Write-PmcStyled -Style 'Error' -Text "Project '$projectName' not found"
            return
        }

        # Check for tasks in this project
        $tasks = $allData.tasks | Where-Object { $_.project -eq $projectName }
        if ($tasks) {
            Write-PmcStyled -Style 'Warning' -Text "Project '$projectName' has $($tasks.Count) tasks. Remove tasks first or use project archive."
            return
        }

        # Remove project
        $allData.projects = $allData.projects | Where-Object { $_.name -ne $projectName }

        Set-PmcAllData $allData
        Write-PmcStyled -Style 'Success' -Text "✓ Project '$projectName' removed"

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error removing project: $_"
    }
}

function Set-PmcProjectArchived {
    param([PmcCommandContext]$Context)

    if (-not $Context -or $Context.FreeText.Count -eq 0) {
        Write-PmcStyled -Style 'Error' -Text "Usage: project archive <name>"
        return
    }

    $projectName = $Context.FreeText[0]

    try {
        $allData = Get-PmcAllData
        $project = $allData.projects | Where-Object { $_.name -eq $projectName }

        if (-not $project) {
            Write-PmcStyled -Style 'Error' -Text "Project '$projectName' not found"
            return
        }

        $project.status = 'archived'

        Set-PmcAllData $allData
        Write-PmcStyled -Style 'Success' -Text "✓ Project '$projectName' archived"

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error archiving project: $_"
    }
}

function Set-PmcProjectFields {
    param([PmcCommandContext]$Context)
    Write-PmcStyled -Style 'Info' -Text "Project fields: name, description, status, created, tags"
}

function Show-PmcProjectFields {
    param([PmcCommandContext]$Context)
    Set-PmcProjectFields -Context $Context
}

function Get-PmcProjectStats {
    param([PmcCommandContext]$Context)

    try {
        $allData = Get-PmcAllData
        $projects = $allData.projects
        $tasks = $allData.tasks

        if (-not $projects) {
            Write-PmcStyled -Style 'Info' -Text "No projects found"
            return
        }

        Write-PmcStyled -Style 'Header' -Text "`nProject Statistics"
        Write-PmcStyled -Style 'Body' -Text "Total Projects: $($projects.Count)"

        $active = $projects | Where-Object { $_.status -eq 'active' }
        $archived = $projects | Where-Object { $_.status -eq 'archived' }

        Write-PmcStyled -Style 'Body' -Text "Active: $($active.Count)"
        Write-PmcStyled -Style 'Body' -Text "Archived: $($archived.Count)"

        if ($tasks) {
            Write-PmcStyled -Style 'Header' -Text "`nTask Distribution"
            foreach ($project in $projects) {
                $projectTasks = $tasks | Where-Object { $_.project -eq $project.name }
                if ($projectTasks) {
                    Write-PmcStyled -Style 'Body' -Text "$($project.name): $($projectTasks.Count) tasks"
                }
            }
        }

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error getting project stats: $_"
    }
}

function Show-PmcProjectInfo {
    param([PmcCommandContext]$Context)
    Show-PmcProject -Context $Context
}

function Get-PmcRecentProjects {
    param([PmcCommandContext]$Context)

    try {
        $allData = Get-PmcAllData
        $projects = $allData.projects | Sort-Object created -Descending | Select-Object -First 5

        if (-not $projects) {
            Write-PmcStyled -Style 'Info' -Text "No projects found"
            return
        }

        Write-PmcStyled -Style 'Header' -Text "`nRecent Projects"
        foreach ($project in $projects) {
            Write-PmcStyled -Style 'Body' -Text "$($project.name) - $($project.created)"
        }

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error getting recent projects: $_"
    }
}

# Export all project functions
Export-ModuleMember -Function Add-PmcProject, Get-PmcProjectList, Show-PmcProject, Set-PmcProject, Edit-PmcProject, Rename-PmcProject, Remove-PmcProject, Set-PmcProjectArchived, Set-PmcProjectFields, Show-PmcProjectFields, Get-PmcProjectStats, Show-PmcProjectInfo, Get-PmcRecentProjects

# END FILE: ./module/Pmc.Strict/src/Projects.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/ProjectWizard.ps1
# SIZE: 16.49 KB
# MODIFIED: 2025-09-22 15:23:10
# ================================================================================

# ProjectWizard.ps1 - Modern guided project creation wizard
# Updated to use current PMC display standards (PmcGridRenderer, Show-PmcDataGrid)

class PmcProjectWizard {
    [hashtable]$ProjectData
    [hashtable]$Templates
    [string]$CurrentStep
    [bool]$IsComplete

    PmcProjectWizard() {
        $this.InitializeWizard()
    }

    [void] InitializeWizard() {
        $this.IsComplete = $false
        $this.CurrentStep = 'template'

        $this.ProjectData = @{
            name = ""
            description = ""
            ID1 = ""
            ID2 = ""
            ProjFolder = ""
            AssignedDate = ""
            DueDate = ""
            BFDate = ""
            CAAName = ""
            RequestName = ""
            T2020 = ""
            icon = "📁"
            sortOrder = 0
            aliases = @()
            color = "Gray"
            isArchived = $false
            created = ""
        }

        $this.InitializeTemplates()
    }

    [void] InitializeTemplates() {
        $this.Templates = @{
            'software' = @{
                Name = 'Software Development'
                Description = 'Full-stack development project with phases'
                Goals = @('Requirements Analysis', 'Design & Architecture', 'Development', 'Testing', 'Deployment')
                TimelineWeeks = 12
                SuggestedTools = @('IDE', 'Version Control', 'Issue Tracker', 'CI/CD')
                DefaultTags = @('development', 'software')
            }
            'marketing' = @{
                Name = 'Marketing Campaign'
                Description = 'Comprehensive marketing campaign planning'
                Goals = @('Market Research', 'Strategy Development', 'Content Creation', 'Campaign Launch', 'Analytics')
                TimelineWeeks = 8
                SuggestedTools = @('Analytics', 'Social Media Tools', 'Design Software', 'Email Platform')
                DefaultTags = @('marketing', 'campaign')
            }
            'research' = @{
                Name = 'Research Project'
                Description = 'Academic or business research initiative'
                Goals = @('Literature Review', 'Methodology Design', 'Data Collection', 'Analysis', 'Report Writing')
                TimelineWeeks = 16
                SuggestedTools = @('Research Database', 'Survey Tools', 'Statistical Software', 'Writing Tools')
                DefaultTags = @('research', 'analysis')
            }
            'event' = @{
                Name = 'Event Planning'
                Description = 'Conference, meeting, or event organization'
                Goals = @('Planning & Budget', 'Venue & Logistics', 'Speaker Coordination', 'Marketing', 'Execution')
                TimelineWeeks = 6
                SuggestedTools = @('Event Platform', 'Registration System', 'Communication Tools', 'Budget Tracker')
                DefaultTags = @('event', 'planning')
            }
            'custom' = @{
                Name = 'Custom Project'
                Description = 'Build your project from scratch'
                Goals = @()
                TimelineWeeks = 4
                SuggestedTools = @()
                DefaultTags = @()
            }
        }
    }

    [void] Start() {
        try {
            Write-PmcStyled -Style 'Header' -Text "`n🚀 PMC Project Creation Wizard"
            Write-PmcStyled -Style 'Body' -Text "This wizard will guide you through creating a project with your actual fields.`n"

            # Step 1: Basic Info (Name, Description, IDs, Folder)
            $this.EditBasicInfo()
            if (-not $this.ProjectData.name) { return }

            # Step 2: Project Dates
            $this.EditDates()

            # Step 3: Review & Create
            $this.ReviewAndCreate()

        } catch {
            Write-PmcStyled -Style 'Error' -Text "Wizard error: $_"
        }
    }

    [void] SelectTemplate() {
        Write-PmcStyled -Style 'Info' -Text "📋 Step 1: Select Project Template"

        # Build template selection data
        $templateRows = @()
        foreach ($key in $this.Templates.Keys) {
            $template = $this.Templates[$key]
            $templateRows += [pscustomobject]@{
                Key = $key
                Name = $template.Name
                Description = $template.Description
                Timeline = "$($template.TimelineWeeks) weeks"
                Tools = ($template.SuggestedTools -join ', ').Substring(0, [Math]::Min(40, ($template.SuggestedTools -join ', ').Length))
            }
        }

        $columns = @{
            Name = @{ Header='Template'; Width=20; Alignment='Left' }
            Description = @{ Header='Description'; Width=35; Alignment='Left' }
            Timeline = @{ Header='Timeline'; Width=12; Alignment='Left' }
            Tools = @{ Header='Suggested Tools'; Width=0; Alignment='Left' }
        }

        $selectedTemplate = $null
        Show-PmcDataGrid -Domains @('wizard-template') -Columns $columns -Data $templateRows -Title 'Project Templates' -Interactive -OnSelectCallback {
            param($item)
            if ($item -and $item.PSObject.Properties['Key']) {
                $selectedTemplate = [string]$item.Key
                Write-PmcStyled -Style 'Success' -Text "✓ Selected: $($item.Name)"
            }
        }

        $this.ProjectData.template = $selectedTemplate
        if ($selectedTemplate -and $this.Templates.ContainsKey($selectedTemplate)) {
            $template = $this.Templates[$selectedTemplate]
            $this.ProjectData.goals = $template.Goals
            $this.ProjectData.tools = $template.SuggestedTools
            $this.ProjectData.tags = $template.DefaultTags

            # Set suggested timeline
            $suggestedEnd = (Get-Date).AddDays($template.TimelineWeeks * 7).ToString("yyyy-MM-dd")
            $this.ProjectData.start_date = (Get-Date).ToString("yyyy-MM-dd")
            $this.ProjectData.deadline = $suggestedEnd
        }
    }

    [void] EditBasicInfo() {
        Write-PmcStyled -Style 'Info' -Text "`n📝 Step 2: Project Details"

        # Create editable project info with ALL your actual fields
        $projectInfo = [pscustomobject]@{
            Name = $this.ProjectData.name
            Description = $this.ProjectData.description
            ID1 = $this.ProjectData.ID1
            ID2 = $this.ProjectData.ID2
            ProjFolder = $this.ProjectData.ProjFolder
            CAAName = $this.ProjectData.CAAName
            RequestName = $this.ProjectData.RequestName
            T2020 = $this.ProjectData.T2020
        }

        $columns = @{
            Name = @{ Header='Project Name'; Width=15; Alignment='Left'; Editable=$true }
            Description = @{ Header='Description'; Width=20; Alignment='Left'; Editable=$true }
            ID1 = @{ Header='ID1'; Width=10; Alignment='Left'; Editable=$true }
            ID2 = @{ Header='ID2'; Width=10; Alignment='Left'; Editable=$true }
            ProjFolder = @{ Header='Project Folder'; Width=15; Alignment='Left'; Editable=$true }
            CAAName = @{ Header='CAA Name'; Width=12; Alignment='Left'; Editable=$true }
            RequestName = @{ Header='Request Name'; Width=15; Alignment='Left'; Editable=$true }
            T2020 = @{ Header='T2020'; Width=10; Alignment='Left'; Editable=$true }
        }

        Write-PmcStyled -Style 'Body' -Text "Edit your project fields. Press Enter to save changes, Q to continue."

        Show-PmcDataGrid -Domains @('wizard-info') -Columns $columns -Data @($projectInfo) -Title 'Project Information' -Interactive -OnSelectCallback {
            param($item)
            if ($item) {
                $this.ProjectData.name = [string]$item.Name
                $this.ProjectData.description = [string]$item.Description
                $this.ProjectData.ID1 = [string]$item.ID1
                $this.ProjectData.ID2 = [string]$item.ID2
                $this.ProjectData.ProjFolder = [string]$item.ProjFolder
                $this.ProjectData.CAAName = [string]$item.CAAName
                $this.ProjectData.RequestName = [string]$item.RequestName
                $this.ProjectData.T2020 = [string]$item.T2020
                Write-PmcStyled -Style 'Success' -Text "✓ Project details saved"
            }
        }
    }

    [void] EditGoals() {
        Write-PmcStyled -Style 'Info' -Text "`n🎯 Step 3: Project Goals"

        if ($this.ProjectData.goals -and $this.ProjectData.goals.Count -gt 0) {
            Write-PmcStyled -Style 'Body' -Text "Template suggested goals (edit as needed):"
        } else {
            Write-PmcStyled -Style 'Body' -Text "Add your project goals:"
        }

        # Convert goals to editable format
        $goalRows = @()
        $goalIndex = 1
        foreach ($goal in $this.ProjectData.goals) {
            $goalRows += [pscustomobject]@{
                Index = $goalIndex
                Goal = $goal
                Status = 'pending'
            }
            $goalIndex++
        }

        # Add empty row for new goal
        $goalRows += [pscustomobject]@{
            Index = $goalIndex
            Goal = ""
            Status = 'pending'
        }

        $columns = @{
            Index = @{ Header='#'; Width=3; Alignment='Right'; Editable=$false }
            Goal = @{ Header='Goal/Milestone'; Width=50; Alignment='Left'; Editable=$true }
            Status = @{ Header='Status'; Width=10; Alignment='Left'; Editable=$false }
        }

        Write-PmcStyled -Style 'Body' -Text "Edit goals below. Add new goals in empty rows. Q to continue."

        Show-PmcDataGrid -Domains @('wizard-goals') -Columns $columns -Data $goalRows -Title 'Project Goals' -Interactive -OnSelectCallback {
            param($item)
            # Extract non-empty goals
            $updatedGoals = @()
            foreach ($row in $goalRows) {
                if ($row.Goal -and $row.Goal.Trim()) {
                    $updatedGoals += $row.Goal.Trim()
                }
            }
            $this.ProjectData.goals = $updatedGoals
            Write-PmcStyled -Style 'Success' -Text "✓ Goals updated ($($updatedGoals.Count) goals)"
        }
    }

    [void] EditDates() {
        Write-PmcStyled -Style 'Info' -Text "`n📅 Step 4: Project Dates"

        $dateData = [pscustomobject]@{
            AssignedDate = $this.ProjectData.AssignedDate
            DueDate = $this.ProjectData.DueDate
            BFDate = $this.ProjectData.BFDate
        }

        $columns = @{
            AssignedDate = @{ Header='Assigned Date'; Width=20; Alignment='Left'; Editable=$true }
            DueDate = @{ Header='Due Date'; Width=20; Alignment='Left'; Editable=$true }
            BFDate = @{ Header='BF Date'; Width=20; Alignment='Left'; Editable=$true }
        }

        Write-PmcStyled -Style 'Body' -Text "Set your project dates. Q to continue."

        Show-PmcDataGrid -Domains @('wizard-dates') -Columns $columns -Data @($dateData) -Title 'Project Dates' -Interactive -OnSelectCallback {
            param($item)
            if ($item) {
                $this.ProjectData.AssignedDate = [string]$item.AssignedDate
                $this.ProjectData.DueDate = [string]$item.DueDate
                $this.ProjectData.BFDate = [string]$item.BFDate
                Write-PmcStyled -Style 'Success' -Text "✓ Dates updated"
            }
        }
    }

    [void] EditResources() {
        Write-PmcStyled -Style 'Info' -Text "`n💼 Step 5: Resources"

        $resourceData = [pscustomobject]@{
            Budget = $this.ProjectData.budget
            Team = ($this.ProjectData.team -join ', ')
            Tools = ($this.ProjectData.tools -join ', ')
            Tags = ($this.ProjectData.tags -join ', ')
        }

        $columns = @{
            Budget = @{ Header='Budget'; Width=15; Alignment='Left'; Editable=$true }
            Team = @{ Header='Team (comma separated)'; Width=25; Alignment='Left'; Editable=$true }
            Tools = @{ Header='Tools (comma separated)'; Width=25; Alignment='Left'; Editable=$true }
            Tags = @{ Header='Tags (comma separated)'; Width=20; Alignment='Left'; Editable=$true }
        }

        Write-PmcStyled -Style 'Body' -Text "Edit project resources. Q to continue."

        Show-PmcDataGrid -Domains @('wizard-resources') -Columns $columns -Data @($resourceData) -Title 'Project Resources' -Interactive -OnSelectCallback {
            param($item)
            if ($item) {
                $this.ProjectData.budget = [string]$item.Budget
                $this.ProjectData.team = @(([string]$item.Team).Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
                $this.ProjectData.tools = @(([string]$item.Tools).Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
                $this.ProjectData.tags = @(([string]$item.Tags).Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
                Write-PmcStyled -Style 'Success' -Text "✓ Resources updated"
            }
        }
    }

    [void] ReviewAndCreate() {
        Write-PmcStyled -Style 'Info' -Text "`n📋 Step 3: Review & Create"

        # Build review summary using ALL actual PMC fields
        $reviewRows = @(
            [pscustomobject]@{ Field='Name'; Value=$this.ProjectData.name }
            [pscustomobject]@{ Field='Description'; Value=$this.ProjectData.description }
            [pscustomobject]@{ Field='ID1'; Value=$this.ProjectData.ID1 }
            [pscustomobject]@{ Field='ID2'; Value=$this.ProjectData.ID2 }
            [pscustomobject]@{ Field='Project Folder'; Value=$this.ProjectData.ProjFolder }
            [pscustomobject]@{ Field='CAA Name'; Value=$this.ProjectData.CAAName }
            [pscustomobject]@{ Field='Request Name'; Value=$this.ProjectData.RequestName }
            [pscustomobject]@{ Field='T2020'; Value=$this.ProjectData.T2020 }
            [pscustomobject]@{ Field='Assigned Date'; Value=$this.ProjectData.AssignedDate }
            [pscustomobject]@{ Field='Due Date'; Value=$this.ProjectData.DueDate }
            [pscustomobject]@{ Field='BF Date'; Value=$this.ProjectData.BFDate }
        )

        $columns = @{
            Field = @{ Header='Field'; Width=15; Alignment='Left'; Editable=$false }
            Value = @{ Header='Value'; Width=0; Alignment='Left'; Editable=$false }
        }

        Write-PmcStyled -Style 'Body' -Text "Review your project details. Press Enter to create the project."

        Show-PmcDataGrid -Domains @('wizard-review') -Columns $columns -Data $reviewRows -Title 'Project Review' -Interactive -OnSelectCallback {
            param($item)
            $this.CreateProject()
        }
    }

    [void] CreateProject() {
        Write-PmcStyled -Style 'Info' -Text "`n🚀 Creating project..."

        try {
            # Create the project directly through data system
            $projectName = $this.ProjectData.name
            Write-PmcStyled -Style 'Body' -Text "Creating project: $projectName"

            # Load existing data
            $allData = Get-PmcAllData

            # Create new project using ALL actual PMC fields
            $newProject = @{
                name = $projectName
                description = $this.ProjectData.description
                ID1 = $this.ProjectData.ID1
                ID2 = $this.ProjectData.ID2
                ProjFolder = $this.ProjectData.ProjFolder
                AssignedDate = $this.ProjectData.AssignedDate
                DueDate = $this.ProjectData.DueDate
                BFDate = $this.ProjectData.BFDate
                CAAName = $this.ProjectData.CAAName
                RequestName = $this.ProjectData.RequestName
                T2020 = $this.ProjectData.T2020
                icon = $this.ProjectData.icon
                color = $this.ProjectData.color
                sortOrder = $this.ProjectData.sortOrder
                aliases = $this.ProjectData.aliases
                isArchived = $this.ProjectData.isArchived
                created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            }

            # Add to data
            if (-not $allData.projects) { $allData.projects = @() }
            $allData.projects += $newProject


            # Save all data
            Set-PmcAllData $allData

            $this.IsComplete = $true

            Write-PmcStyled -Style 'Success' -Text "`n✓ Project '$projectName' created successfully!"
            Write-PmcStyled -Style 'Body' -Text "`nUse 'projects' to view your new project."

        } catch {
            Write-PmcStyled -Style 'Error' -Text "✗ Error creating project: $_"
        }
    }
}

# Export the wizard function for PMC command integration
function Start-PmcProjectWizard {
    param([PmcCommandContext]$Context)

    $wizard = [PmcProjectWizard]::new()
    $wizard.Start()
}

# Export module member
Export-ModuleMember -Function Start-PmcProjectWizard

# END FILE: ./module/Pmc.Strict/src/ProjectWizard.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/Query.ps1
# SIZE: 23.53 KB
# MODIFIED: 2025-09-24 05:31:11
# ================================================================================

# PMC Query Language implementation and command processors

Set-StrictMode -Version Latest

function Invoke-PmcQuery {
    param($Context)

    # Handle both string and PmcCommandContext parameters for backward compatibility
    if ($Context -is [string]) {
        $tokens = ConvertTo-PmcTokens $Context
        Write-PmcDebug -Level 1 -Category 'Query' -Message 'Invoke-PmcQuery START (string input)' -Data @{ TokenCount=@($tokens).Count }
    } else {
        Write-PmcDebug -Level 1 -Category 'Query' -Message 'Invoke-PmcQuery START' -Data @{ FreeTextCount=@($Context.FreeText).Count }
        if (-not $Context -or $Context.FreeText.Count -lt 1) {
            Write-PmcStyled -Style 'Warning' -Text "Usage: q <tasks|projects|timelogs> [filters/directives]"
            return
        }
        $tokens = @($Context.FreeText)
    }

    # Usage: pmc q <tasks|projects|timelogs> [tokens ...]
    if (-not $tokens -or @($tokens).Count -lt 1) {
        Write-PmcStyled -Style 'Warning' -Text "Usage: q <tasks|projects|timelogs> [filters/directives]"
        return
    }
    $interactive = $false
    # Detect short interactive flag and strip it from tokens
    if ($tokens -contains '-i') {
        $interactive = $true
        $tokens = @($tokens | Where-Object { $_ -ne '-i' })
    }

    # Handle load: alias early
    $loadAlias = $tokens | Where-Object { $_ -match '^(?i)load:(.+)$' } | Select-Object -First 1
    if ($loadAlias) {
        $aliasName = ($loadAlias -replace '^(?i)load:','')
        $loaded = Get-PmcQueryAlias -Name $aliasName
        if ($loaded) { $tokens = @($loaded) } else { Write-PmcStyled -Style 'Error' -Text ("Unknown query alias '{0}'" -f $aliasName); return }
    }
    $domTok = [string]$tokens[0]
    $rest = @($tokens | Select-Object -Skip 1)

    # Normalize domain token to singular
    switch ($domTok.ToLower()) {
        'task' { $domain = 'task' }
        'tasks' { $domain = 'task' }
        'project' { $domain = 'project' }
        'projects' { $domain = 'project' }
        'timelog' { $domain = 'timelog' }
        'timelogs' { $domain = 'timelog' }
        default { Write-PmcStyled -Style 'Error' -Text ("Unknown domain '{0}'. Use tasks|projects|timelogs" -f $domTok); return }
    }

    $spec = [PmcQuerySpec]::new()
    $spec.Domain = $domain
    $spec.RawTokens = $rest

    # Parse directives: cols:, metrics:, sort:, with:, group:, view:
    $colsList = @()
    $metricsList = @()
    $sortList = @()
    $withList = @()
    $groupField = ''
    $textTerms = @()
    $viewType = ''
    foreach ($t in $rest) {
        if ($t -match '^(?i)cols:(.+)$') {
            $list = $matches[1]
            foreach ($c in ($list -split ',')) { $cv = $c.Trim(); if ($cv) { $colsList += $cv } }
        }
        elseif ($t -match '^(?i)metrics:(.+)$') {
            $list = $matches[1]
            foreach ($m in ($list -split ',')) { $mv = $m.Trim(); if ($mv) { $metricsList += $mv } }
        }
        elseif ($t -match '^(?i)sort:(.+)$') {
            $list = $matches[1]
            foreach ($s in ($list -split ',')) {
                $sv = $s.Trim(); if (-not $sv) { continue }
                $dir = 'Asc'; $field = $sv
                if ($sv.EndsWith('+')) { $field = $sv.Substring(0, $sv.Length-1); $dir='Asc' }
                elseif ($sv.EndsWith('-')) { $field = $sv.Substring(0, $sv.Length-1); $dir='Desc' }
                if ($field) { $sortList += @{ Field=$field; Dir=$dir } }
            }
        }
        elseif ($t -match '^(?i)with:(.+)$') {
            $val = $matches[1].ToLower()
            if ($val) { $withList += $val }
        }
        elseif ($t -match '^(?i)group:(.+)$') {
            $groupField = $matches[1]
        }
        elseif ($t -match '^(?i)view:(.+)$') {
            $v = $matches[1].ToLower()
            if ($v -in @('list','kanban')) { $viewType = $v }
        }
        elseif ($t -match '^@(.+)$') { $spec.Filters['project'] = $matches[1] }
        elseif ($t -match '^(?i)overdue$') { $spec.Filters['overdue'] = $true }
        elseif ($t -match '^(?i)due:(.+)$') {
            $dv = $matches[1]
            $spec.Filters['due'] = $dv
        }
        elseif ($t -match '^(?i)due:(\d{4}-\d{2}-\d{2})\.\.(\d{4}-\d{2}-\d{2})$') {
            $spec.Filters['due_range'] = @{ Start=$matches[1]; End=$matches[2] }
        }
        elseif ($t -match '^(?i)p:([1-3])\.\.([1-3])$') { $spec.Filters['p_range'] = @{ Min=[int]$matches[1]; Max=[int]$matches[2] } }
        elseif ($t -match '^(?i)status:(pending|done)$') { $spec.Filters['status'] = $matches[1].ToLower() }
        elseif ($t -match '^(?i)archived:(true|false)$') { $spec.Filters['archived'] = ([bool]::Parse($matches[1])) }
        elseif ($t -match '^(?i)date:(.+)$') { $spec.Filters['date'] = $matches[1] }
        elseif ($t -match '^(?i)task:(\d+)$') { $spec.Filters['taskId'] = [int]$matches[1] }
        elseif ($t -match '^(?i)p<=([1-3])$') { $spec.Filters['p_le'] = [int]$matches[1] }
        elseif ($t -match '^(?i)p_le=([1-3])$') { $spec.Filters['p_le'] = [int]$matches[1] }
        elseif ($t -match '^(?i)p>=([1-3])$') { $spec.Filters['p_ge'] = [int]$matches[1] }
        elseif ($t -match '^(?i)p_ge=([1-3])$') { $spec.Filters['p_ge'] = [int]$matches[1] }
        elseif ($t -match '^(?i)p>([1-3])$') { $spec.Filters['p_gt'] = [int]$matches[1] }
        elseif ($t -match '^(?i)p_gt=([1-3])$') { $spec.Filters['p_gt'] = [int]$matches[1] }
        elseif ($t -match '^(?i)p<([1-3])$') { $spec.Filters['p_lt'] = [int]$matches[1] }
        elseif ($t -match '^(?i)p_lt=([1-3])$') { $spec.Filters['p_lt'] = [int]$matches[1] }
        elseif ($t -match '^(?i)p([1-3])$') { $spec.Filters['p_eq'] = [int]$matches[1] }
        elseif ($t -match '^(?i)due>(.+)$') { $spec.Filters['due_gt'] = $matches[1] }
        elseif ($t -match '^(?i)due<(.+)$') { $spec.Filters['due_lt'] = $matches[1] }
        elseif ($t -match '^(?i)due>=(.+)$') { $spec.Filters['due_ge'] = $matches[1] }
        elseif ($t -match '^(?i)due<=(.+)$') { $spec.Filters['due_le'] = $matches[1] }
        elseif ($t -match '^#(.+)$') {
            if (-not $spec.Filters.ContainsKey('tags_in')) { $spec.Filters['tags_in'] = @() }
            $spec.Filters['tags_in'] += $matches[1]
        }
        elseif ($t -match '^-(?:tag:)?(.+)$') {
            if (-not $spec.Filters.ContainsKey('tags_out')) { $spec.Filters['tags_out'] = @() }
            $spec.Filters['tags_out'] += $matches[1]
        }
        elseif ($t -match '^"(.+)"$') { $textTerms += $matches[1] }
        else { if ($t) { $textTerms += $t } }
    }
    if (@($colsList).Count -gt 0) { $spec.Columns = $colsList }
    if (@($metricsList).Count -gt 0) { $spec.Metrics = $metricsList }
    if (@($sortList).Count -gt 0) { $spec.Sort = $sortList }
    if (@($withList).Count -gt 0) { $spec.With = $withList }
    if ($groupField) { $spec.Group = $groupField }
    if (@($textTerms).Count -gt 0) { $spec.Filters['text'] = ($textTerms -join ' ') }
    if ($viewType) { $spec.View = $viewType }

    # Smart defaults: Auto-sort by due date if filtering by due
    if ($spec.Filters.ContainsKey('due') -and @($spec.Sort).Count -eq 0) {
        $spec.Sort = @(@{ Field='due'; Dir='Asc' })
        Write-PmcDebug -Level 2 -Category 'Query' -Message 'Auto-sorting by due date'
    }

    # Smart defaults: Auto-sort by priority if filtering by priority
    if (($spec.Filters.ContainsKey('p_le') -or $spec.Filters.ContainsKey('p_eq') -or $spec.Filters.ContainsKey('p_range')) -and @($spec.Sort).Count -eq 0) {
        $spec.Sort = @(@{ Field='priority'; Dir='Asc' })
        Write-PmcDebug -Level 2 -Category 'Query' -Message 'Auto-sorting by priority'
    }

    # Smart defaults: Enable kanban view if grouping by status
    if ($spec.Group -eq 'status' -and $spec.View -eq 'list') {
        $spec.View = 'kanban'
        Write-PmcDebug -Level 2 -Category 'Query' -Message 'Auto-switching to kanban view for status grouping'
    }

    # Validate filter values
    $priorityFilters = @('p_le', 'p_ge', 'p_gt', 'p_lt', 'p_eq')
    foreach ($pf in $priorityFilters) {
        if ($spec.Filters.ContainsKey($pf)) {
            $val = $spec.Filters[$pf]
            if ($val -lt 1 -or $val -gt 3) {
                Write-PmcStyled -Style 'Warning' -Text "Warning: Priority value '$val' should be between 1-3"
            }
        }
    }

    # Validate date filters
    $dateFilters = @('due', 'due_gt', 'due_lt', 'due_ge', 'due_le')
    foreach ($df in $dateFilters) {
        if ($spec.Filters.ContainsKey($df)) {
            $dateTok = $spec.Filters[$df]
            $isValid = $false
            try {
                if ($dateTok -match '^(?i)today$') { $isValid = $true }
                elseif ($dateTok -match '^\d{4}-\d{2}-\d{2}$') {
                    try { [datetime]$dateTok | Out-Null; $isValid = $true } catch { $isValid = $false }
                }
                else {
                    $schemas = Get-PmcFieldSchemasForDomain -Domain 'task'
                    if ($schemas.ContainsKey('due') -and $schemas.due.ContainsKey('Normalize')) {
                        $normalizedDate = & $schemas.due.Normalize $dateTok
                        if ($normalizedDate) { $isValid = $true }
                    }
                }
            } catch { $isValid = $false }

            if (-not $isValid) {
                Write-PmcStyled -Style 'Warning' -Text "Warning: Invalid date format '$dateTok'. Use YYYY-MM-DD, 'today', or relative dates like '+1d'"
            }
        }
    }

    # Build Columns hashtable if cols provided; else use defaults
    $columns = @{}
    if (@($spec.Columns).Count -gt 0) {
        $fs = Get-PmcFieldSchemasForDomain -Domain $spec.Domain
        foreach ($name in $spec.Columns) {
            if (-not $fs.ContainsKey($name)) { Write-PmcStyled -Style 'Warning' -Text ("Unknown column '{0}' for {1}" -f $name, $spec.Domain); continue }
            $sch = $fs[$name]
            $w = if ($sch.ContainsKey('DefaultWidth')) { [int]$sch.DefaultWidth } else { 12 }
            $al = 'Left'
            switch ($name) { 'id' { $al='Right' } 'priority' { $al='Center' } 'due' { $al='Center' } default { } }
            $columns[$name] = @{ Header = ($name); Width = $w; Alignment = $al }
        }
    } else {
        # Default columns based on domain
        if ($spec.Domain -eq 'task') {
            $columns = @{
                'id' = @{ Header = 'ID'; Width = 4; Alignment = 'Right' }
                'text' = @{ Header = 'Task'; Width = 0; Alignment = 'Left' }
                'priority' = @{ Header = 'pri'; Width = 3; Alignment = 'Center' }
                'due' = @{ Header = 'Due'; Width = 12; Alignment = 'Center' }
                'status' = @{ Header = 'Status'; Width = 10; Alignment = 'Left' }
            }
        } elseif ($spec.Domain -eq 'project') {
            $columns = @{
                'name' = @{ Header = 'Name'; Width = 0; Alignment = 'Left' }
                'description' = @{ Header = 'Description'; Width = 0; Alignment = 'Left' }
            }
        } elseif ($spec.Domain -eq 'timelog') {
            $columns = @{
                'date' = @{ Header = 'Date'; Width = 12; Alignment = 'Center' }
                'project' = @{ Header = 'Project'; Width = 15; Alignment = 'Left' }
                'notes' = @{ Header = 'Notes'; Width = 0; Alignment = 'Left' }
            }
        }
    }

    # Validate metrics before evaluating
    if (@($spec.Metrics).Count -gt 0) {
        $validMetrics = Get-PmcMetricsForDomain -Domain $spec.Domain
        $invalidMetrics = @($spec.Metrics | Where-Object { -not $validMetrics.ContainsKey($_) })
        if (@($invalidMetrics).Count -gt 0) {
            Write-PmcStyled -Style 'Warning' -Text ("Unknown metrics for {0}: {1}" -f $spec.Domain, ($invalidMetrics -join ', '))
            Write-PmcStyled -Style 'Muted' -Text ("Available metrics: {0}" -f ($validMetrics.Keys -join ', '))
        }
    }

    # Evaluate
    try {
        $result = Evaluate-PmcQuery -Spec $spec
        Write-PmcDebug -Level 2 -Category 'Query' -Message 'Query evaluation completed' -Data @{ RowCount=@($result.Rows).Count }
    } catch {
        Write-PmcStyled -Style 'Error' -Text "Query evaluation failed: $($_.Exception.Message)"
        Write-PmcDebug -Level 1 -Category 'Query' -Message 'Query evaluation failed' -Data @{ Error=$_.Exception.Message }
        return
    }

    # Append to history
    Write-PmcDebug -Level 2 -Category 'Query' -Message 'Adding to query history'
    try { Add-PmcQueryHistory -Args ($Context.FreeText -join ' ') } catch {}

    # If metrics requested and not in columns, append them to columns end
    Write-PmcDebug -Level 2 -Category 'Query' -Message 'Processing metrics' -Data @{ MetricsCount=@($spec.Metrics).Count }
    if (@($spec.Metrics).Count -gt 0) {
        foreach ($m in $spec.Metrics) {
            if (-not $columns.ContainsKey($m)) {
                $columns[$m] = @{ Header = $m; Width = 10; Alignment = 'Right' }
            }
        }
    }

    # Show custom grid with evaluated rows
    Write-PmcDebug -Level 2 -Category "Query" -Message "About to call Show-PmcCustomGrid with $(@($result.Rows).Count) rows"
    Write-PmcDebug -Level 2 -Category 'Query' -Message 'Calling Show-PmcCustomGrid' -Data @{ Domain=$spec.Domain; RowCount=@($result.Rows).Count; ColumnCount=@($columns.Keys).Count }
    try {
        if ($interactive) {
            Show-PmcCustomGrid -Domain $spec.Domain -Columns $columns -Data $result.Rows -Group $spec.Group -View $spec.View -Interactive
        } else {
            Show-PmcCustomGrid -Domain $spec.Domain -Columns $columns -Data $result.Rows -Group $spec.Group -View $spec.View
        }
        Write-PmcDebug -Level 2 -Category "Query" -Message "Show-PmcCustomGrid completed successfully"
    } catch {
        Write-PmcDebug -Level 1 -Category "Query" -Message "Show-PmcCustomGrid failed: $($_.Exception.Message)"
        Write-PmcDebug -Level 1 -Category 'Query' -Message 'Show-PmcCustomGrid failed' -Data @{ Error=$_.Exception.Message }
    }
    Write-PmcDebug -Level 2 -Category 'Query' -Message 'Show-PmcCustomGrid completed'

    # Save alias if requested
    $saveAlias = $rest | Where-Object { $_ -match '^(?i)save:(.+)$' } | Select-Object -First 1
    if ($saveAlias) {
        $aliasName = ($saveAlias -replace '^(?i)save:','')
        try { Set-PmcQueryAlias -Name $aliasName -Args ($Context.FreeText -join ' ') } catch {}
    }
}

# Simple completer scaffold for q (progressively enhance later)
function Register-PmcQueryCompleter {
    try {
        Register-ArgumentCompleter -CommandName q -ScriptBlock {
            param($wordToComplete, $commandAst, $cursorPosition)

            function New-CR([string]$text,[string]$tooltip=$text) { [System.Management.Automation.CompletionResult]::new($text,$text,'ParameterValue',$tooltip) }

            $line = $commandAst.ToString()
            $tokens = [regex]::Split($line.Trim(), '\s+')
            # tokens[0] = 'q'
            if ($tokens.Count -le 1) { return @( New-CR 'tasks' ; New-CR 'projects' ; New-CR 'timelogs' ) }

            # Domain candidates (second token)
            if ($tokens.Count -eq 2) {
                $doms = @('tasks','projects','timelogs')
                return @($doms | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object { New-CR $_ })
            }

            # Determine domain
            $domTok = $tokens[1].ToLower()
            $domain = switch ($domTok) { 'tasks' {'task'} 'task' {'task'} 'projects' {'project'} 'project' {'project'} 'timelogs' {'timelog'} 'timelog' {'timelog'} default { '' } }

            # Completers for prefixes
            $results = @()

            # Directives starter
            $directiveStarters = @('with:','metrics:','cols:','sort:','group:','view:','limit:','offset:')
            foreach ($d in $directiveStarters) { if ($d -like "$wordToComplete*") { $results += (New-CR $d) } }

            # Helper for comma-separated lists
            function Complete-CommaList([string]$word,[string]$prefix,[string[]]$candidates) {
                $out = @()
                if (-not ($word -like "$prefix*")) { return $out }
                $tail = $word.Substring($prefix.Length)
                $parts = @($tail -split ',')
                if ($parts.Count -eq 0) { $parts = @('') }
                $existing = @()
                if ($parts.Count -gt 1) { $existing = $parts[0..($parts.Count-2)] }
                $partial = $parts[$parts.Count-1]
                foreach ($cand in $candidates) {
                    if ($cand -like "$partial*") {
                        $newList = @($existing + $cand) -join ','
                        $out += (New-CR ("$prefix$newList"))
                    }
                }
                return $out
            }

            # with: completions
            if ($wordToComplete -like 'with:*') {
                $rels = @()
                switch ($domain) {
                    'task'    { $rels = @('project','time') }
                    'project' { $rels = @('tasks','time') }
                    'timelog' { $rels = @('project','task') }
                    default { $rels = @() }
                }
                $results += Complete-CommaList -word $wordToComplete -prefix 'with:' -candidates $rels
                return $results
            }

            # metrics: completions
            if ($wordToComplete -like 'metrics:*') {
                $met = Get-PmcMetricsForDomain -Domain $domain
                $results += Complete-CommaList -word $wordToComplete -prefix 'metrics:' -candidates (@($met.Keys))
                return $results
            }

            # cols: completions
            if ($wordToComplete -like 'cols:*') {
                $fs = Get-PmcFieldSchemasForDomain -Domain $domain
                $all = @($fs.Keys)
                $met = Get-PmcMetricsForDomain -Domain $domain
                $all += @($met.Keys)
                $results += Complete-CommaList -word $wordToComplete -prefix 'cols:' -candidates $all
                return $results
            }

            # sort: completions
            if ($wordToComplete -like 'sort:*') {
                $fs = Get-PmcFieldSchemasForDomain -Domain $domain
                $items = @()
                foreach ($k in $fs.Keys) { $items += @("$k+","$k-") }
                $met = Get-PmcMetricsForDomain -Domain $domain
                foreach ($k in $met.Keys) { $items += @("$k+","$k-") }
                $results += Complete-CommaList -word $wordToComplete -prefix 'sort:' -candidates $items
                return $results
            }

            # group: completions (include relation-derived if with:project present)
            if ($wordToComplete -like 'group:*') {
                $fs = Get-PmcFieldSchemasForDomain -Domain $domain
                foreach ($k in $fs.Keys) { $txt = "group:$k"; if ($txt -like "$wordToComplete*") { $results += (New-CR $txt) } }
                $hasWithProject = ($tokens -match '^with:project(,|$)').Count -gt 0
                if ($hasWithProject) { foreach ($k in @('project_name')) { $txt = "group:$k"; if ($txt -like "$wordToComplete*") { $results += (New-CR $txt) } } }
                return $results
            }

            # view: completions
            if ($wordToComplete -like 'view:*') {
                foreach ($v in @('list','kanban')) { $txt = "view:$v"; if ($txt -like "$wordToComplete*") { $results += (New-CR $txt) } }
                return $results
            }

            # @project completion
            if ($wordToComplete -like '@*') {
                try {
                    $data = Get-PmcDataAlias
                    $projects = @($data.projects | ForEach-Object { try { [string]$_.name } catch { $null } } | Where-Object { $_ })
                    foreach ($p in $projects) { $txt = "@$p"; if ($txt -like "$wordToComplete*") { $results += (New-CR $txt) } }
                } catch {}
                return $results
            }

            # priority suggestions
            foreach ($p in @('p1','p2','p3','p<=1','p<=2','p<=3','p:1..2','p:2..3')) { if ($p -like "$wordToComplete*") { $results += (New-CR $p) } }

            # due suggestions
            foreach ($d in @('due:today','due:tomorrow','due:+7','date:today','date:tomorrow')) { if ($d -like "$wordToComplete*") { $results += (New-CR $d) } }

            # status / archived starters
            foreach ($s in @('status:pending','status:done','archived:true','archived:false','task:')) { if ($s -like "$wordToComplete*") { $results += (New-CR $s) } }

            # tags suggestion starter
            if ($wordToComplete -eq '#' -or $wordToComplete -like '#*' -or $wordToComplete -like '-tag:*') {
                try {
                    $data = Get-PmcDataAlias
                    $tags = @()
                    foreach ($t in @($data.tasks)) { try { if ($t -and $t.PSObject.Properties['tags']) { $tags += @($t.tags) } } catch {} }
                    $tags = @($tags | Where-Object { $_ } | Select-Object -Unique | Sort-Object)
                    foreach ($tg in $tags) {
                        $cand1 = "#$tg"; if ($cand1 -like "$wordToComplete*") { $results += (New-CR $cand1) }
                        $cand2 = "-tag:$tg"; if ($cand2 -like "$wordToComplete*") { $results += (New-CR $cand2) }
                    }
                } catch {}
                return $results
            }

            # Default: show directive starters and a few filter hints
            $base = @('with:','metrics:','cols:','sort:','group:','@','p1','p2','p3','due:today','#')
            foreach ($b in $base) { if ($b -like "$wordToComplete*") { $results += (New-CR $b) } }
            return $results
        } | Out-Null
    } catch { }
}

# Register on import
Register-PmcQueryCompleter

# Query alias/history helpers
function Get-PmcQueryStoreDir {
    try { $root = Get-PmcRootPath } catch { $root = (Get-Location).Path }
    $dir = Join-Path $root '.pmc'
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    return $dir
}

function Get-PmcQueryAliasPath { param([string]$Name)
    $dir = Get-PmcQueryStoreDir
    return (Join-Path $dir 'query_aliases.json')
}

function Get-PmcQueryHistoryPath {
    $dir = Get-PmcQueryStoreDir
    return (Join-Path $dir 'query_history.log')
}

function Get-PmcQueryAlias { param([string]$Name)
    $path = Get-PmcQueryAliasPath -Name $Name
    if (-not (Test-Path $path)) { return $null }
    try {
        $json = Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($json.PSObject.Properties[$Name]) { return @([string]$json.$Name) }
    } catch {}
    return $null
}

function Set-PmcQueryAlias { param([string]$Name,[string]$Args)
    if ([string]::IsNullOrWhiteSpace($Name)) { return }
    $path = Get-PmcQueryAliasPath -Name $Name
    $map = @{}
    if (Test-Path $path) { try { $map = Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json } catch { $map=@{} } }
    $map[$Name] = $Args
    try { ($map | ConvertTo-Json -Depth 5) | Set-Content -Path $path -Encoding UTF8 } catch {}
}

function Add-PmcQueryHistory { param([string]$Args)
    $path = Get-PmcQueryHistoryPath
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | q $Args"
    try { Add-Content -Path $path -Value $line -Encoding UTF8 } catch {}
}

function Get-PmcQueryHistory { param([int]$Last = 10)
    $path = Get-PmcQueryHistoryPath
    if (-not (Test-Path $path)) { return @() }
    try {
        $lines = Get-Content -Path $path -Encoding UTF8 -ErrorAction SilentlyContinue
        $queries = @()
        foreach ($line in ($lines | Select-Object -Last $Last)) {
            if ($line -match '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} \| q (.+)$') {
                $queries += $matches[1]
            }
        }
        return $queries
    } catch { return @() }
}

#Export-ModuleMember -Function Invoke-PmcQuery, Register-PmcQueryCompleter, Get-PmcQueryStoreDir, Get-PmcQueryAliasPath, Get-PmcQueryHistoryPath, Get-PmcQueryAlias, Set-PmcQueryAlias, Add-PmcQueryHistory, Get-PmcQueryHistory


# END FILE: ./module/Pmc.Strict/src/Query.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/QueryEvaluator.ps1
# SIZE: 15.49 KB
# MODIFIED: 2025-09-23 17:05:28
# ================================================================================

# Query evaluation engine for the PMC query language system

Set-StrictMode -Version Latest

function Evaluate-PmcQuery {
    param([PmcQuerySpec]$Spec)
    if (-not $Spec -or -not $Spec.Domain) { throw 'Evaluate-PmcQuery: Spec/Domain required' }

    Write-PmcDebug -Level 2 -Category 'QueryEvaluator' -Message 'Starting query evaluation' -Data @{ Domain=$Spec.Domain }

    $data = Get-PmcDataAlias
    $rows = @()
    switch ($Spec.Domain) {
        'task'    { $rows = if ($data.tasks) { @($data.tasks | Where-Object { $_ -ne $null }) } else { @() } }
        'project' { $rows = if ($data.projects) { @($data.projects | Where-Object { $_ -ne $null }) } else { @() } }
        'timelog' { $rows = if ($data.timelogs) { @($data.timelogs | Where-Object { $_ -ne $null }) } else { @() } }
        default   { $rows = @() }
    }

    # Apply basic filters (task domain)
    if ($Spec.Domain -eq 'task' -and $Spec.Filters) {
        $proj = if ($Spec.Filters.ContainsKey('project')) { [string]$Spec.Filters['project'] } else { $null }
        $overdue = ($Spec.Filters.ContainsKey('overdue'))
        $dueTok = if ($Spec.Filters.ContainsKey('due')) { [string]$Spec.Filters['due'] } else { $null }
        $due_gt = if ($Spec.Filters.ContainsKey('due_gt')) { [string]$Spec.Filters['due_gt'] } else { $null }
        $due_lt = if ($Spec.Filters.ContainsKey('due_lt')) { [string]$Spec.Filters['due_lt'] } else { $null }
        $due_ge = if ($Spec.Filters.ContainsKey('due_ge')) { [string]$Spec.Filters['due_ge'] } else { $null }
        $due_le = if ($Spec.Filters.ContainsKey('due_le')) { [string]$Spec.Filters['due_le'] } else { $null }
        $p_le = if ($Spec.Filters.ContainsKey('p_le')) { [int]$Spec.Filters['p_le'] } else { 0 }
        $p_ge = if ($Spec.Filters.ContainsKey('p_ge')) { [int]$Spec.Filters['p_ge'] } else { 0 }
        $p_gt = if ($Spec.Filters.ContainsKey('p_gt')) { [int]$Spec.Filters['p_gt'] } else { 0 }
        $p_lt = if ($Spec.Filters.ContainsKey('p_lt')) { [int]$Spec.Filters['p_lt'] } else { 0 }
        $p_eq = if ($Spec.Filters.ContainsKey('p_eq')) { [int]$Spec.Filters['p_eq'] } else { 0 }
        $tagsIn = if ($Spec.Filters.ContainsKey('tags_in')) { @($Spec.Filters['tags_in']) } else { @() }
        $tagsOut = if ($Spec.Filters.ContainsKey('tags_out')) { @($Spec.Filters['tags_out']) } else { @() }
        $textQ = if ($Spec.Filters.ContainsKey('text')) { [string]$Spec.Filters['text'] } else { '' }

        $rows = @($rows | Where-Object {
            $ok = $true
            if ($proj) { $ok = $ok -and ($_.PSObject.Properties['project'] -and [string]$_.project -eq $proj) }
            if ($Spec.Filters.ContainsKey('status')) {
                $sts = [string]$Spec.Filters['status']
                $ok = $ok -and ($_.PSObject.Properties['status'] -and ([string]$_.status).ToLower() -eq $sts)
            }
            if ($p_le -gt 0) {
                $v = if ($_.PSObject.Properties['priority']) { try { [int]$_.priority } catch { 0 } } else { 0 }
                $ok = $ok -and ($v -gt 0 -and $v -le $p_le)
            }
            if ($p_ge -gt 0) {
                $v = if ($_.PSObject.Properties['priority']) { try { [int]$_.priority } catch { 0 } } else { 0 }
                $ok = $ok -and ($v -gt 0 -and $v -ge $p_ge)
            }
            if ($p_gt -gt 0) {
                $v = if ($_.PSObject.Properties['priority']) { try { [int]$_.priority } catch { 0 } } else { 0 }
                $ok = $ok -and ($v -gt $p_gt)
            }
            if ($p_lt -gt 0) {
                $v = if ($_.PSObject.Properties['priority']) { try { [int]$_.priority } catch { 0 } } else { 0 }
                $ok = $ok -and ($v -gt 0 -and $v -lt $p_lt)
            }
            if ($p_eq -gt 0) {
                $v = if ($_.PSObject.Properties['priority']) { try { [int]$_.priority } catch { 0 } } else { 0 }
                $ok = $ok -and ($v -eq $p_eq)
            }
            if ($Spec.Filters.ContainsKey('p_range')) {
                $min = [int]$Spec.Filters['p_range'].Min; $max=[int]$Spec.Filters['p_range'].Max
                $v = if ($_.PSObject.Properties['priority']) { try { [int]$_.priority } catch { 0 } } else { 0 }
                $ok = $ok -and ($v -ge $min -and $v -le $max)
            }
            if ($overdue) {
                if ($_.PSObject.Properties['due']) {
                    try { $ok = $ok -and (([datetime]$_.due).Date -lt (Get-Date).Date) } catch { $ok = $false }
                }
            }
            if ($dueTok) {
                $d = $null
                try {
                    # Use flexible date parsing logic from FieldSchemas
                    $schemas = Get-PmcFieldSchemasForDomain -Domain 'task'
                    if ($schemas.ContainsKey('due') -and $schemas.due.ContainsKey('Normalize')) {
                        $normalizedDate = & $schemas.due.Normalize $dueTok
                        if ($normalizedDate) { $d = [datetime]$normalizedDate }
                    }
                } catch {
                    # Fallback to basic parsing
                    if ($dueTok -match '^(?i)today$') { $d = (Get-Date).Date }
                    elseif ($dueTok -match '^\d{4}-\d{2}-\d{2}$') { try { $d = [datetime]$dueTok } catch { $d=$null } }
                }
                if ($d -ne $null -and $_.PSObject.Properties['due']) {
                    try { $ok = $ok -and (([datetime]$_.due).Date -eq $d.Date) } catch { $ok = $false }
                }
            }
            if ($Spec.Filters.ContainsKey('due_range')) {
                $startTok = [string]$Spec.Filters['due_range'].Start; $endTok=[string]$Spec.Filters['due_range'].End
                try { $start=[datetime]$startTok; $end=[datetime]$endTok } catch { $start=$null; $end=$null }
                if ($start -ne $null -and $end -ne $null -and $_.PSObject.Properties['due']) {
                    try { $dd=[datetime]$_.due; $ok = $ok -and ($dd -ge $start -and $dd -le $end) } catch { $ok = $false }
                }
            }
            if ($due_gt -and $_.PSObject.Properties['due']) {
                $d = $null
                try {
                    $schemas = Get-PmcFieldSchemasForDomain -Domain 'task'
                    if ($schemas.ContainsKey('due') -and $schemas.due.ContainsKey('Normalize')) {
                        $normalizedDate = & $schemas.due.Normalize $due_gt
                        if ($normalizedDate) { $d = [datetime]$normalizedDate }
                    }
                } catch {
                    if ($due_gt -match '^(?i)today$') { $d = (Get-Date).Date }
                    elseif ($due_gt -match '^\d{4}-\d{2}-\d{2}$') { try { $d = [datetime]$due_gt } catch { $d=$null } }
                }
                if ($d -ne $null) {
                    try { $ok = $ok -and (([datetime]$_.due).Date -gt $d.Date) } catch { $ok = $false }
                }
            }
            if ($due_lt -and $_.PSObject.Properties['due']) {
                $d = $null
                try {
                    $schemas = Get-PmcFieldSchemasForDomain -Domain 'task'
                    if ($schemas.ContainsKey('due') -and $schemas.due.ContainsKey('Normalize')) {
                        $normalizedDate = & $schemas.due.Normalize $due_lt
                        if ($normalizedDate) { $d = [datetime]$normalizedDate }
                    }
                } catch {
                    if ($due_lt -match '^(?i)today$') { $d = (Get-Date).Date }
                    elseif ($due_lt -match '^\d{4}-\d{2}-\d{2}$') { try { $d = [datetime]$due_lt } catch { $d=$null } }
                }
                if ($d -ne $null) {
                    try { $ok = $ok -and (([datetime]$_.due).Date -lt $d.Date) } catch { $ok = $false }
                }
            }
            if ($due_ge -and $_.PSObject.Properties['due']) {
                $d = $null
                try {
                    $schemas = Get-PmcFieldSchemasForDomain -Domain 'task'
                    if ($schemas.ContainsKey('due') -and $schemas.due.ContainsKey('Normalize')) {
                        $normalizedDate = & $schemas.due.Normalize $due_ge
                        if ($normalizedDate) { $d = [datetime]$normalizedDate }
                    }
                } catch {
                    if ($due_ge -match '^(?i)today$') { $d = (Get-Date).Date }
                    elseif ($due_ge -match '^\d{4}-\d{2}-\d{2}$') { try { $d = [datetime]$due_ge } catch { $d=$null } }
                }
                if ($d -ne $null) {
                    try { $ok = $ok -and (([datetime]$_.due).Date -ge $d.Date) } catch { $ok = $false }
                }
            }
            if ($due_le -and $_.PSObject.Properties['due']) {
                $d = $null
                try {
                    $schemas = Get-PmcFieldSchemasForDomain -Domain 'task'
                    if ($schemas.ContainsKey('due') -and $schemas.due.ContainsKey('Normalize')) {
                        $normalizedDate = & $schemas.due.Normalize $due_le
                        if ($normalizedDate) { $d = [datetime]$normalizedDate }
                    }
                } catch {
                    if ($due_le -match '^(?i)today$') { $d = (Get-Date).Date }
                    elseif ($due_le -match '^\d{4}-\d{2}-\d{2}$') { try { $d = [datetime]$due_le } catch { $d=$null } }
                }
                if ($d -ne $null) {
                    try { $ok = $ok -and (([datetime]$_.due).Date -le $d.Date) } catch { $ok = $false }
                }
            }
            if (@($tagsIn).Count -gt 0) {
                if ($_.PSObject.Properties['tags']) {
                    try { $ok = $ok -and (@($tagsIn | Where-Object { $($_) -in $_.tags }).Count -eq @($tagsIn).Count) } catch { $ok = $false }
                }
            }
            if (@($tagsOut).Count -gt 0) {
                if ($_.PSObject.Properties['tags']) {
                    try { $ok = $ok -and -not (@($tagsOut | Where-Object { $($_) -in $_.tags }).Count -gt 0) } catch { $ok = $true }
                }
            }
            if ($textQ) {
                if ($_.PSObject.Properties['text']) {
                    try { $ok = $ok -and ([string]$_.text).ToLower().Contains($textQ.ToLower()) } catch { $ok = $false }
                }
            }
            $ok
        })
    }

    # Apply basic filters (project domain)
    if ($Spec.Domain -eq 'project' -and $Spec.Filters) {
        $textQ = if ($Spec.Filters.ContainsKey('text')) { [string]$Spec.Filters['text'] } else { '' }
        $arch = $null; if ($Spec.Filters.ContainsKey('archived')) { $arch = [bool]$Spec.Filters['archived'] }
        if ($textQ) {
            $rows = @($rows | Where-Object {
                try {
                    ($_.PSObject.Properties['name'] -and ([string]$_.name).ToLower().Contains($textQ.ToLower())) -or
                    ($_.PSObject.Properties['description'] -and ([string]$_.description).ToLower().Contains($textQ.ToLower()))
                } catch { $false }
            })
        }
        if ($arch -ne $null) {
            $rows = @($rows | Where-Object { $_.PSObject.Properties['isArchived'] -and [bool]$_.isArchived -eq $arch })
        }
    }

    # Apply basic filters (timelog domain)
    if ($Spec.Domain -eq 'timelog' -and $Spec.Filters) {
        $proj = if ($Spec.Filters.ContainsKey('project')) { [string]$Spec.Filters['project'] } else { $null }
        $dateTok = if ($Spec.Filters.ContainsKey('date')) { [string]$Spec.Filters['date'] } elseif ($Spec.Filters.ContainsKey('due')) { [string]$Spec.Filters['due'] } else { $null }
        $textQ = if ($Spec.Filters.ContainsKey('text')) { [string]$Spec.Filters['text'] } else { '' }
        $taskId = if ($Spec.Filters.ContainsKey('taskId')) { [int]$Spec.Filters['taskId'] } else { 0 }
        $rows = @($rows | Where-Object {
            $ok = $true
            if ($proj) { $ok = $ok -and ($_.PSObject.Properties['project'] -and [string]$_.project -eq $proj) }
            if ($dateTok) {
                if ($dateTok -match '^\d{4}-\d{2}-\d{2}\.\.\d{4}-\d{2}-\d{2}$') {
                    $parts = $dateTok -split '\.\.'
                    try { $ds=[datetime]$parts[0]; $de=[datetime]$parts[1] } catch { $ds=$null; $de=$null }
                    if ($ds -ne $null -and $de -ne $null -and $_.PSObject.Properties['date']) {
                        try { $dd=[datetime]$_.date; $ok = $ok -and ($dd -ge $ds -and $dd -le $de) } catch { $ok = $false }
                    }
                } else {
                    $d = $null
                    if ($dateTok -match '^(?i)today$') { $d = (Get-Date).Date }
                    elseif ($dateTok -match '^\d{4}-\d{2}-\d{2}$') { try { $d = [datetime]$dateTok } catch { $d=$null } }
                    if ($d -ne $null -and $_.PSObject.Properties['date']) {
                        try { $ok = $ok -and (([datetime]$_.date).Date -eq $d.Date) } catch { $ok = $false }
                    }
                }
            }
            if ($taskId -gt 0 -and $_.PSObject.Properties['taskId']) {
                try { $ok = $ok -and ([int]$_.taskId -eq $taskId) } catch { $ok = $false }
            }
            if ($textQ -and $_.PSObject.Properties['notes']) {
                try { $ok = $ok -and ([string]$_.notes).ToLower().Contains($textQ.ToLower()) } catch { $ok = $false }
            }
            $ok
        })
    }

    # Relations (attach derived fields)
    Write-PmcDebug -Level 3 -Category 'QueryEvaluator' -Message 'Checking relations' -Data @{ With=$Spec.With; WithType=($Spec.With).GetType().Name }
    if ($Spec.With -and @($Spec.With).Count -gt 0) {
        foreach ($rel in $Spec.With) {
            foreach ($row in $rows) {
                $rels = Get-PmcRelationResolvers -Domain $Spec.Domain -Relation $rel
                foreach ($key in $rels.Keys) {
                    try { $val = & $rels[$key] $row $data } catch { $val = $null }
                    try { if ($row.PSObject.Properties[$key]) { $row.$key = $val } else { Add-Member -InputObject $row -MemberType NoteProperty -Name $key -NotePropertyValue $val -Force } } catch {}
                }
            }
        }
    }

    # Compute requested metrics and attach as NoteProperties
    Write-PmcDebug -Level 3 -Category 'QueryEvaluator' -Message 'Checking metrics' -Data @{ Metrics=$Spec.Metrics; MetricsType=($Spec.Metrics).GetType().Name }
    if ($Spec.Metrics -and @($Spec.Metrics).Count -gt 0) {
        $metrics = Get-PmcMetricsForDomain -Domain $Spec.Domain
        foreach ($row in $rows) {
            foreach ($m in $Spec.Metrics) {
                if (-not $metrics.ContainsKey($m)) { continue }
                $def = $metrics[$m]
                try {
                    $val = & $def.Resolver $row $data
                } catch { $val = $null }
                    try { if ($row.PSObject.Properties[$m]) { $row.$m = $val } else { Add-Member -InputObject $row -MemberType NoteProperty -Name $m -NotePropertyValue $val -Force } } catch {}
            }
        }
    }

    # Apply group pre-sort (simple group ascending)
    if ($Spec.Group -and $Spec.Group.Trim()) {
        $g = $Spec.Group.Trim()
        $rows = @($rows | Sort-Object -Property $g)
    }

    # Apply sort if specified
    Write-PmcDebug -Level 3 -Category 'QueryEvaluator' -Message 'Checking sort' -Data @{ Sort=$Spec.Sort; SortType=($Spec.Sort).GetType().Name }
    if ($Spec.Sort -and @($Spec.Sort).Count -gt 0) {
        $props = @()
        foreach ($s in $Spec.Sort) {
            $f = [string]$s.Field; if (-not $f) { continue }
            $asc = ($s.Dir -ne 'Desc')
            $props += @{ Expression = $f; Ascending = $asc }
        }
        if (@($props).Count -gt 0) { $rows = @($rows | Sort-Object -Property $props) }
    }

    return @{ Domain=$Spec.Domain; Rows=$rows }
}

Export-ModuleMember -Function Evaluate-PmcQuery


# END FILE: ./module/Pmc.Strict/src/QueryEvaluator.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/QuerySpec.ps1
# SIZE: 0.77 KB
# MODIFIED: 2025-09-20 09:34:03
# ================================================================================

# Query specification classes for the PMC query language system

Set-StrictMode -Version Latest

class PmcQuerySpec {
    [string] $Domain = ''       # task|project|timelog
    [string[]] $Columns = @()   # visible columns in order
    [string[]] $RawTokens = @() # raw query tokens (post 'q')
    [string[]] $Metrics = @()
    [hashtable[]] $Sort = @()   # e.g., @{ Field='due'; Dir='Asc' }
    [string[]] $With = @()
    [string] $Group = ''
    [hashtable] $Filters = @{}
    [string] $View = 'list'     # list | kanban (future)

    PmcQuerySpec() {
        $this.Columns = @()
        $this.RawTokens = @()
        $this.Metrics = @()
        $this.Sort = @()
        $this.With = @()
        $this.Filters = @{}
    }
}

# QuerySpec.ps1 contains only classes, no functions to export


# END FILE: ./module/Pmc.Strict/src/QuerySpec.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/Resolvers.ps1
# SIZE: 1.11 KB
# MODIFIED: 2025-09-22 15:23:10
# ================================================================================

# Project and argument resolvers for strict engine

Set-StrictMode -Version Latest

function Resolve-Project {
    param(
        [Parameter(Mandatory=$true)] $Data,
        [Parameter(Mandatory=$true)][string] $Name
    )
    if ([string]::IsNullOrWhiteSpace($Name)) { return $null }
    $q = $Name.Trim(); if ($q.StartsWith('@')) { $q = $q.Substring(1) }
    # Exact name match (case-insensitive)
    $p = $Data.projects | Where-Object { try { $_.name -and ($_.name.ToLower() -eq $q.ToLower()) } catch { $false } } | Select-Object -First 1
    if ($p) { return $p }
    # Alias match (case-insensitive)
    foreach ($proj in $Data.projects) {
        try {
            if (Pmc-HasProp $proj 'aliases' -and $proj.aliases) {
                foreach ($alias in $proj.aliases) {
                    if ([string]::IsNullOrWhiteSpace($alias)) { continue }
                    if ($alias.ToLower() -eq $q.ToLower()) { return $proj }
                }
            }
        } catch {
            # Project alias property access failed - skip this project
        }
    }
    return $null
}

#Export-ModuleMember -Function Resolve-Project


# END FILE: ./module/Pmc.Strict/src/Resolvers.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/Review.ps1
# SIZE: 1.28 KB
# MODIFIED: 2025-09-22 15:23:10
# ================================================================================

# Weekly Review workflow

function Start-PmcReview {
    param([PmcCommandContext]$Context)
    Write-Host ([PraxisVT]::ClearScreen())
    Show-PmcHeader -Title 'WEEKLY REVIEW' -Icon '🗓'
    Show-PmcTip 'Walk through overdue, today/tomorrow, upcoming, blocked, and projects.'

    $sections = @(
        @{ title='Overdue';        action={ param($ctx) Show-PmcOverdueTasks -Context $ctx } },
        @{ title='Today & Tomorrow'; action={ param($ctx) Show-PmcTodayTasks -Context $ctx; Show-PmcTomorrowTasks -Context $ctx } },
        @{ title='Upcoming (7d)'; action={ param($ctx) Show-PmcUpcomingTasks -Context $ctx } },
        @{ title='Blocked';       action={ param($ctx) Show-PmcBlockedTasks -Context $ctx } },
        @{ title='Next Actions';  action={ param($ctx) Show-PmcNextTasks -Context $ctx } },
        @{ title='Projects';      action={ param($ctx) Show-PmcProjectsView -Context $ctx } }
    )

    foreach ($s in $sections) {
        Show-PmcSeparator -Width 60
        Show-PmcNotice ("Section: {0}" -f $s.title)
        & $s.action $Context
        $resp = Read-Host "Press Enter to continue, or 'q' to quit review"
        if ($resp -match '^(?i)q$') { break }
    }

    Show-PmcSeparator -Width 60
    Show-PmcSuccess 'Review complete.'
}

#Export-ModuleMember -Function Start-PmcReview



# END FILE: ./module/Pmc.Strict/src/Review.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/Schemas.ps1
# SIZE: 6.77 KB
# MODIFIED: 2025-09-22 15:23:10
# ================================================================================

# Parameter schemas for strict commands (subset to start)

# Each entry uses a simple schema array: ordered hints and prefixes
$Script:PmcParameterMap = @{
    'task add' = @(
        @{ Name='Text'; Type='FreeText'; Required=$true; Description='Task description' },
        @{ Name='Project'; Prefix='@'; Type='ProjectName' },
        @{ Name='Priority'; Prefix='p'; Type='Priority'; Pattern='^p[1-3]$' },
        @{ Name='Due'; Prefix='due:'; Type='DateString' },
        @{ Name='Tags'; Prefix='#'; Type='TagName'; AllowsMultiple=$true }
    )
    'task done' = @(
        @{ Name='Id'; Type='TaskID'; Required=$true; Pattern='^\d+$' }
    )
    'task list' = @()
    'task delete' = @()
    'task view' = @(
        @{ Name='Id'; Type='TaskID'; Required=$true }
    )
    'task agenda' = @()
    'task week' = @()
    'task month' = @()
    'time log' = @(
        @{ Name='Project'; Prefix='@'; Type='ProjectName' },
        @{ Name='TaskId'; Prefix='task:'; Type='TaskID' },
        @{ Name='Date'; Type='DateString' },
        @{ Name='Duration'; Type='Duration' },
        @{ Name='Description'; Type='FreeText' }
    )
    'time report' = @(
        @{ Name='Range'; Type='DateRange' },
        @{ Name='Project'; Prefix='@'; Type='ProjectName' }
    )
    'time list' = @()
    'time edit' = @(
        @{ Name='Id'; Type='FreeText'; Required=$true }
    )
    'time delete' = @(
        @{ Name='Id'; Type='FreeText'; Required=$true }
    )
    'timer start' = @(
        @{ Name='Project'; Prefix='@'; Type='ProjectName' },
        @{ Name='Description'; Type='FreeText' }
    )
    'timer stop' = @()
    'timer status' = @()
    'task update' = @(
        @{ Name='Id'; Type='TaskID'; Required=$true },
        @{ Name='Project'; Prefix='@'; Type='ProjectName' },
        @{ Name='Priority'; Prefix='p'; Type='Priority' },
        @{ Name='Due'; Prefix='due:'; Type='DateString' },
        @{ Name='Tags'; Prefix='#'; Type='TagName'; AllowsMultiple=$true },
        @{ Name='Text'; Type='FreeText' }
    )
    'task move' = @(
        @{ Name='Id'; Type='TaskID'; Required=$true },
        @{ Name='Project'; Prefix='@'; Type='ProjectName'; Required=$true }
    )
    'task postpone' = @(
        @{ Name='Id'; Type='TaskID'; Required=$true },
        @{ Name='Delta'; Type='FreeText'; Required=$true }
    )
    'task duplicate' = @(
        @{ Name='Id'; Type='TaskID'; Required=$true }
    )
    'task note' = @(
        @{ Name='Id'; Type='TaskID'; Required=$true },
        @{ Name='Note'; Type='FreeText'; Required=$true }
    )
    'task edit' = @(
        @{ Name='Id'; Type='TaskID'; Required=$true }
    )
    'task search' = @(
        @{ Name='Query'; Type='FreeText'; Required=$true }
    )
    'task priority' = @(
        @{ Name='Level'; Type='FreeText'; Required=$true }
    )

    # Project advanced
    'project add' = @(
        # Name is optional to allow launching the Project Wizard when omitted
        @{ Name='Name'; Type='FreeText'; Required=$false }
    )
    'project list' = @()
    'project stats' = @()
    'project info' = @()
    'project recent' = @()
    'project view' = @(
        @{ Name='Name'; Type='FreeText'; Required=$true }
    )
    'project rename' = @(
        @{ Name='Old'; Type='FreeText'; Required=$true },
        @{ Name='New'; Type='FreeText'; Required=$true }
    )
    'project delete' = @(
        @{ Name='Name'; Type='FreeText'; Required=$true }
    )
    'project archive' = @(
        @{ Name='Name'; Type='FreeText'; Required=$true }
    )
    'project set-fields' = @(
        @{ Name='Project'; Prefix='@'; Type='ProjectName'; Required=$true },
        @{ Name='Fields'; Type='FreeText' }
    )
    'project show-fields' = @(
        @{ Name='Project'; Prefix='@'; Type='ProjectName'; Required=$true }
    )
    'project update' = @(
        @{ Name='Project'; Prefix='@'; Type='ProjectName'; Required=$true },
        @{ Name='Fields'; Type='FreeText' }
    )
    'project edit' = @(
        @{ Name='Project'; Prefix='@'; Type='ProjectName'; Required=$true }
    )

    # Config / Template / Recurring
    'config show' = @()
    'config icons' = @()
    'config set' = @(
        @{ Name='Path'; Type='FreeText'; Required=$true },
        @{ Name='Value'; Type='FreeText'; Required=$true }
    )
    'config edit' = @()

    'template save' = @(
        @{ Name='Name'; Type='FreeText'; Required=$true },
        @{ Name='Body'; Type='FreeText' }
    )
    'template apply' = @(
        @{ Name='Name'; Type='FreeText'; Required=$true }
    )
    'template list' = @()
    'template remove' = @(
        @{ Name='Name'; Type='FreeText'; Required=$true }
    )

    'recurring add' = @(
        @{ Name='Pattern'; Type='FreeText'; Required=$true },
        @{ Name='Body'; Type='FreeText' }
    )
    'recurring list' = @()

    # Dependencies
    'dep add' = @(
        @{ Name='Id'; Type='TaskID'; Required=$true },
        @{ Name='Requires'; Type='FreeText'; Required=$true }
    )
    'dep remove' = @(
        @{ Name='Id'; Type='TaskID'; Required=$true },
        @{ Name='Requires'; Type='FreeText'; Required=$true }
    )
    'dep show' = @(
        @{ Name='Id'; Type='TaskID'; Required=$true }
    )
    'dep graph' = @()

    # Activity / System
    'activity list' = @()
    'system undo' = @()
    'system redo' = @()
    'system backup' = @()
    'system clean' = @()
    'theme reset' = @()
    'theme adjust' = @()

    # Theme management (complete)
    'theme list' = @()
    'theme apply' = @(
        @{ Name='ColorOrPreset'; Type='FreeText'; Required=$true; Description='Color #RRGGBB or preset name' }
    )
    'theme info' = @()
    'excel import' = @()
    'excel bind' = @()
    'excel view' = @()
    'excel latest' = @()
    'import tasks' = @()
    'export tasks' = @()
    'focus set' = @(
        @{ Name='Project'; Type='FreeText'; Required=$true }
    )
    'focus clear' = @()
    'focus status' = @()
    'interactive status' = @()
    'show aliases' = @()
    'show commands' = @()
    'alias add' = @(
        @{ Name='NameAndExpansion'; Type='FreeText'; Required=$true }
    )
    'alias remove' = @(
        @{ Name='Name'; Type='FreeText'; Required=$true }
    )
    'help all' = @()
    'help show' = @()
    'help commands' = @()
    'help examples' = @()
    'help guide' = @()
    'help domain' = @(
        @{ Name='Domain'; Type='FreeText'; Required=$true; Description='Domain name (e.g., task, project, time)' }
    )
    'help command' = @(
        @{ Name='Domain'; Type='FreeText'; Required=$true; Description='Domain name' },
        @{ Name='Action'; Type='FreeText'; Required=$true; Description='Action name' }
    )

    # Views
    'view today' = @()
    'view tomorrow' = @()
    'view overdue' = @()
    'view upcoming' = @()
    'view blocked' = @()
    'view noduedate' = @()
    'view projects' = @()
    'view next' = @()
}

# Schemas.ps1 contains only data structures, no functions to export


# END FILE: ./module/Pmc.Strict/src/Schemas.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/ScreenManager.ps1
# SIZE: 12.47 KB
# MODIFIED: 2025-09-24 05:23:29
# ================================================================================

# PMC Screen Management System
# Adapted from praxis-main/Core patterns for persistent screen layout

class PmcScreenBounds {
    [int]$X = 0
    [int]$Y = 0
    [int]$Width = 0
    [int]$Height = 0

    PmcScreenBounds([int]$x, [int]$y, [int]$width, [int]$height) {
        $this.X = $x
        $this.Y = $y
        $this.Width = $width
        $this.Height = $height
    }

    [string] ToString() {
        return "($($this.X),$($this.Y) $($this.Width)x$($this.Height))"
    }
}

class PmcScreenRegions {
    [PmcScreenBounds]$Header
    [PmcScreenBounds]$Content
    [PmcScreenBounds]$Status
    [PmcScreenBounds]$Input
    [PmcScreenBounds]$Full

    PmcScreenRegions([int]$terminalWidth, [int]$terminalHeight) {
        # Calculate regions based on terminal size
        $this.Full = [PmcScreenBounds]::new(0, 0, $terminalWidth, $terminalHeight)
        $this.Header = [PmcScreenBounds]::new(0, 0, $terminalWidth, 3)  # Title + separator
        $this.Input = [PmcScreenBounds]::new(0, $terminalHeight - 2, $terminalWidth, 2)  # Input line + separator
        $this.Status = [PmcScreenBounds]::new($terminalWidth - 30, 1, 30, 1)  # Right side of header
        $this.Content = [PmcScreenBounds]::new(0, 3, $terminalWidth, $terminalHeight - 5)  # Between header and input

        if (Get-Command Write-PmcDebug -ErrorAction SilentlyContinue) {
            Write-PmcDebug -Level 3 -Category 'ScreenManager' -Message "Screen regions calculated" -Data @{
                Terminal = "$terminalWidth x $terminalHeight"
                Header = $this.Header.ToString()
                Content = $this.Content.ToString()
                Status = $this.Status.ToString()
                Input = $this.Input.ToString()
            }
        }
    }
}

class PmcScreenManager {
    hidden [PmcScreenRegions]$_regions
    hidden [string]$_lastContent = ""
    hidden [bool]$_needsClear = $true
    hidden [int]$_terminalWidth = 0
    hidden [int]$_terminalHeight = 0

    # VT100 sequences - adapted from praxis patterns
    hidden [string]$_hideCursor = "`e[?25l"
    hidden [string]$_showCursor = "`e[?25h"
    hidden [string]$_clearScreen = "`e[2J"
    hidden [string]$_home = "`e[H"

    PmcScreenManager() {
        $this.UpdateTerminalDimensions()
    }

    # Update terminal dimensions and recalculate regions
    [void] UpdateTerminalDimensions() {
        try {
            $newWidth = [Math]::Max([Console]::WindowWidth, 80)
            $newHeight = [Math]::Max([Console]::WindowHeight, 24)

            if ($newWidth -ne $this._terminalWidth -or $newHeight -ne $this._terminalHeight) {
                $this._terminalWidth = $newWidth
                $this._terminalHeight = $newHeight
                $this._regions = [PmcScreenRegions]::new($newWidth, $newHeight)
                $this._needsClear = $true

                if (Get-Command Write-PmcDebug -ErrorAction SilentlyContinue) {
                    Write-PmcDebug -Level 2 -Category 'ScreenManager' -Message "Terminal dimensions updated" -Data @{
                        Width = $newWidth
                        Height = $newHeight
                    }
                }
            }
        } catch {
            if (Get-Command Write-PmcDebug -ErrorAction SilentlyContinue) {
                Write-PmcDebug -Level 1 -Category 'ScreenManager' -Message "Failed to get terminal dimensions" -Data @{ Error = $_.ToString() }
            }
            # Fallback to defaults
            if ($this._terminalWidth -eq 0) {
                $this._terminalWidth = 120
                $this._terminalHeight = 30
                $this._regions = [PmcScreenRegions]::new(120, 30)
            }
        }
    }

    # Get current screen regions
    [PmcScreenRegions] GetRegions() {
        $this.UpdateTerminalDimensions()
        return $this._regions
    }

    # Clear entire screen and set up persistent layout
    [void] ClearScreen() {
        Write-Host $this._clearScreen -NoNewline
        Write-Host $this._home -NoNewline
        Write-Host $this._hideCursor -NoNewline
        $this._needsClear = $false
        $this._lastContent = ""

        if (Get-Command Write-PmcDebug -ErrorAction SilentlyContinue) {
            Write-PmcDebug -Level 3 -Category 'ScreenManager' -Message "Screen cleared and cursor hidden"
        }
    }

    # Clear only the content region (preserves header/input/status)
    [void] ClearContentRegion() {
        if (-not $this._regions) { $this.UpdateTerminalDimensions() }

        $content = $this._regions.Content
        $clearLine = " " * $content.Width

        for ($y = 0; $y -lt $content.Height; $y++) {
            $this.MoveTo($content.X, $content.Y + $y)
            Write-Host $clearLine -NoNewline
        }

        if (Get-Command Write-PmcDebug -ErrorAction SilentlyContinue) {
            Write-PmcDebug -Level 3 -Category 'ScreenManager' -Message "Content region cleared" -Data @{
                Bounds = $content.ToString()
            }
        }
    }

    # Position cursor at specific coordinates
    [void] MoveTo([int]$x, [int]$y) {
        Write-Host "`e[$y;$($x)H" -NoNewline
    }

    # Write text at specific position in a region
    [void] WriteAtPosition([PmcScreenBounds]$region, [int]$offsetX, [int]$offsetY, [string]$text) {
        $actualX = $region.X + $offsetX
        $actualY = $region.Y + $offsetY

        # Bounds checking
        if ($actualX -ge ($region.X + $region.Width) -or $actualY -ge ($region.Y + $region.Height)) {
            if (Get-Command Write-PmcDebug -ErrorAction SilentlyContinue) {
                Write-PmcDebug -Level 2 -Category 'ScreenManager' -Message "Text position out of bounds" -Data @{
                    RequestedX = $actualX
                    RequestedY = $actualY
                    RegionBounds = $region.ToString()
                }
            }
            return
        }

        $this.MoveTo($actualX, $actualY)

        # Truncate text if it would exceed region width
        $maxWidth = $region.Width - $offsetX
        if ($text.Length -gt $maxWidth) {
            $text = $text.Substring(0, $maxWidth - 3) + "..."
        }

        Write-Host $text -NoNewline
    }

    # Render header with title and status
    [void] RenderHeader([string]$title, [string]$status = "") {
        if (-not $this._regions) { $this.UpdateTerminalDimensions() }

        # Clear header region
        $header = $this._regions.Header
        $clearLine = " " * $header.Width
        $this.MoveTo($header.X, $header.Y)
        Write-Host $clearLine -NoNewline

        # Write title
        $this.WriteAtPosition($header, 0, 0, $title)

        # Write status on right side
        if ($status) {
            $statusPos = $header.Width - $status.Length - 1
            if ($statusPos -gt $title.Length + 2) {
                $this.WriteAtPosition($header, $statusPos, 0, $status)
            }
        }

        # Draw separator line
        $this.MoveTo($header.X, $header.Y + 1)
        Write-Host ("─" * $header.Width) -NoNewline

        if (Get-Command Write-PmcDebug -ErrorAction SilentlyContinue) {
            Write-PmcDebug -Level 3 -Category 'ScreenManager' -Message "Header rendered" -Data @{
                Title = $title
                Status = $status
            }
        }
    }

    # Render input prompt at bottom
    [void] RenderInputPrompt([string]$prompt) {
        if (-not $this._regions) { $this.UpdateTerminalDimensions() }

        $input = $this._regions.Input

        # Draw separator line above input
        $this.MoveTo($input.X, $input.Y)
        Write-Host ("─" * $input.Width) -NoNewline

        # Clear input line
        $this.MoveTo($input.X, $input.Y + 1)
        $clearLine = " " * $input.Width
        Write-Host $clearLine -NoNewline

        # Write prompt
        $this.WriteAtPosition($input, 0, 1, $prompt)

        # Position cursor after prompt for input
        $this.MoveTo($input.X + $prompt.Length, $input.Y + 1)
        Write-Host $this._showCursor -NoNewline

        if (Get-Command Write-PmcDebug -ErrorAction SilentlyContinue) {
            Write-PmcDebug -Level 3 -Category 'ScreenManager' -Message "Input prompt rendered" -Data @{
                Prompt = $prompt
            }
        }
    }

    # Show cursor for input
    [void] ShowCursor() {
        Write-Host $this._showCursor -NoNewline
    }

    # Hide cursor for display
    [void] HideCursor() {
        Write-Host $this._hideCursor -NoNewline
    }

    # Get content region for components to render into
    [PmcScreenBounds] GetContentBounds() {
        if (-not $this._regions) { $this.UpdateTerminalDimensions() }
        return $this._regions.Content
    }

    # Set up initial screen layout
    [void] Initialize([string]$title = "PMC — Project Management Console") {
        $this.ClearScreen()
        $this.RenderHeader($title, "")
        $this.RenderInputPrompt("pmc> ")

        if (Get-Command Write-PmcDebug -ErrorAction SilentlyContinue) {
            Write-PmcDebug -Level 2 -Category 'ScreenManager' -Message "Screen manager initialized" -Data @{
                Title = $title
                Regions = $this._regions
            }
        }
    }

    # Cleanup on exit
    [void] Cleanup() {
        $this.ShowCursor()
        $this.ClearScreen()
        if (Get-Command Write-PmcDebug -ErrorAction SilentlyContinue) {
            Write-PmcDebug -Level 2 -Category 'ScreenManager' -Message "Screen manager cleanup completed"
        }
    }
}

# Global screen manager instance
$Script:PmcScreenManager = [PmcScreenManager]::new()

# Public functions for screen management
function Initialize-PmcScreen {
    param(
        [string]$Title = "PMC — Project Management Console"
    )

    $Script:PmcScreenManager.Initialize($Title)
    if (Get-Command Write-PmcDebug -ErrorAction SilentlyContinue) {
        Write-PmcDebug -Level 1 -Category 'ScreenManager' -Message "PMC screen initialized" -Data @{ Title = $Title }
    }
}

function Clear-PmcContentArea {
    $Script:PmcScreenManager.ClearContentRegion()
    if (Get-Command Write-PmcDebug -ErrorAction SilentlyContinue) {
        Write-PmcDebug -Level 2 -Category 'ScreenManager' -Message "PMC content area cleared"
    }
}

function Get-PmcContentBounds {
    return $Script:PmcScreenManager.GetContentBounds()
}

function Set-PmcHeader {
    param(
        [string]$Title,
        [string]$Status = ""
    )

    $Script:PmcScreenManager.RenderHeader($Title, $Status)
}

# Update header with dynamic status chips (focus, debug, security)
function Update-PmcHeaderStatus {
    param(
        [string]$Title = "pmc — enhanced project management console"
    )

    $statusParts = @()
    try {
        # Focus context
        if (Get-Command Get-PmcCurrentContext -ErrorAction SilentlyContinue) {
            $ctx = [string](Get-PmcCurrentContext)
            if ($ctx -and $ctx.ToLower() -ne 'inbox') { $statusParts += ("🎯 " + $ctx) }
        }
    } catch {}

    try {
        # Debug level
        if (Get-Command Get-PmcDebugStatus -ErrorAction SilentlyContinue) {
            $dbg = Get-PmcDebugStatus
            if ($dbg -and $dbg.Enabled) { $statusParts += ("DBG:" + ([string]$dbg.Level)) }
        }
    } catch {}

    try {
        # Security mode (simplified)
        if (Get-Command Get-PmcSecurityStatus -ErrorAction SilentlyContinue) {
            $sec = Get-PmcSecurityStatus
            if ($sec) {
                $secStr = if ($sec.PathWhitelistEnabled) { 'SEC:ON' } else { 'SEC:OFF' }
                $statusParts += $secStr
            }
        }
    } catch {}

    $statusText = ($statusParts -join '  ')
    Set-PmcHeader -Title $Title -Status $statusText
}

function Set-PmcInputPrompt {
    param(
        [string]$Prompt = "pmc> "
    )

    $Script:PmcScreenManager.RenderInputPrompt($Prompt)
}

function Hide-PmcCursor {
    $Script:PmcScreenManager.HideCursor()
}

function Show-PmcCursor {
    $Script:PmcScreenManager.ShowCursor()
}

function Reset-PmcScreen {
    $Script:PmcScreenManager.Cleanup()
}

function Write-PmcAtPosition {
    param(
        [int]$X,
        [int]$Y,
        [string]$Text
    )

    $contentBounds = Get-PmcContentBounds
    $Script:PmcScreenManager.WriteAtPosition($contentBounds, $X, $Y, $Text)
}

function Clear-CommandOutput {
    Clear-PmcContentArea
    if (Get-Command Write-PmcDebug -ErrorAction SilentlyContinue) {
        Write-PmcDebug -Level 2 -Category 'ScreenManager' -Message "Command output area cleared"
    }
}

# Export screen management functions
Export-ModuleMember -Function Initialize-PmcScreen, Clear-PmcContentArea, Get-PmcContentBounds, Set-PmcHeader, Update-PmcHeaderStatus, Set-PmcInputPrompt, Hide-PmcCursor, Show-PmcCursor, Reset-PmcScreen, Write-PmcAtPosition, Clear-CommandOutput


# END FILE: ./module/Pmc.Strict/src/ScreenManager.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/Security.ps1
# SIZE: 18.74 KB
# MODIFIED: 2025-09-22 15:23:10
# ================================================================================

# Security and Safety Hardening for PMC
# Input validation, path protection, resource limits, and execution safety

Set-StrictMode -Version Latest

# Security system state - now managed by centralized state
# State initialization moved to State.ps1

function Initialize-PmcSecuritySystem {
    <#
    .SYNOPSIS
    Initializes security system based on configuration
    #>

    # Defer config loading to avoid circular dependency during initialization
    # Configuration will be applied later via Update-PmcSecurityFromConfig

    # Default allowed paths if none configured
    $securityState = Get-PmcSecurityState
    if ($securityState.AllowedWritePaths.Count -eq 0) {
        $root = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
        $defaultPaths = @(
            $root
            Join-Path $root 'reports'
            Join-Path $root 'backups'
            Join-Path $root 'exports'
            [System.IO.Path]::GetTempPath()
        )
        Set-PmcState -Section 'Security' -Key 'AllowedWritePaths' -Value $defaultPaths
    }
}

function Test-PmcInputSafety {
    <#
    .SYNOPSIS
    Validates input for potential security issues

    .PARAMETER Input
    User input to validate

    .PARAMETER InputType
    Type of input (command, text, path, etc.)
    #>
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Input,

        [string]$InputType = 'general'
    )

    $securityState = Get-PmcSecurityState
    if (-not $securityState.InputValidationEnabled) { return $true }

    $threats = @()

    try {
        # Check for command injection patterns
        $injectionPatterns = @(
            ';.*(?:rm|del|format|shutdown|reboot)',
            '\|.*(?:nc|netcat|wget|curl|powershell|cmd)',
            '&.*(?:ping|nslookup|whoami|net\s)',
            '`.*(?:Get-.*|Invoke-.*|Start-.*)',
            '\$\(.*(?:Get-.*|Invoke-.*|Remove-.*)\)',
            '(?:>|>>).*(?:/etc/|C:\\Windows\\)',
            '(?:\.\.[\\/]){3,}',  # Path traversal
            '(?i)(?:javascript:|data:|vbscript:)',  # Script injection
            '(?i)(?:<script|<iframe|<object|<embed)',  # HTML injection
            'eval\s*\(',  # Code evaluation
            '(?:exec|system|shell_exec|passthru)\s*\('  # System execution
        )

        foreach ($pattern in $injectionPatterns) {
            if ($Input -match $pattern) {
                $threats += "Potential injection: $pattern"
            }
        }

        # Check for sensitive data exposure
        if ($securityState.SensitiveDataScanEnabled) {
            $sensitivePatterns = @(
                '\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b',  # Credit card
                '\b\d{3}-\d{2}-\d{4}\b',  # SSN
                '\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',  # Email
                '\b[0-9a-fA-F]{32,}\b',  # Long hex (potential secrets)
                '(?i)(password|passwd|secret|token|key)\s*[:=]\s*\S+',  # Credentials
                'BEGIN\s+(RSA\s+)?PRIVATE\s+KEY',  # Private keys
                'sk_live_[0-9a-zA-Z]{24}',  # Stripe keys
                'AIza[0-9A-Za-z\\-_]{35}',  # Google API keys
                'ya29\\.[0-9A-Za-z\\-_]+',  # Google OAuth
                'AKIA[0-9A-Z]{16}'  # AWS access keys
            )

            foreach ($pattern in $sensitivePatterns) {
                if ($Input -match $pattern) {
                    $threats += "Potential sensitive data: $pattern"
                }
            }
        }

        # Input length validation
        if ($Input.Length -gt 10000) {
            $threats += "Input too long (${$Input.Length} chars, max 10000)"
        }

        # Null byte injection
        if ($Input.Contains("`0")) {
            $threats += "Null byte injection detected"
        }

        # Unicode normalization attacks
        if ($Input -match '[\u202A-\u202E\u2066-\u2069]') {
            $threats += "Unicode direction override detected"
        }

        if ($threats.Count -gt 0) {
            Write-PmcDebug -Level 1 -Category 'SECURITY' -Message "Input validation failed" -Data @{ Input = $Input.Substring(0, [Math]::Min($Input.Length, 100)); Threats = $threats; Type = $InputType }
            return $false
        }

        Write-PmcDebug -Level 3 -Category 'SECURITY' -Message "Input validation passed" -Data @{ Length = $Input.Length; Type = $InputType }
        return $true

    } catch {
        Write-PmcDebug -Level 1 -Category 'SECURITY' -Message "Input validation error: $_"
        return $false
    }
}

function Test-PmcPathSafety {
    <#
    .SYNOPSIS
    Validates that a file path is safe to write to

    .PARAMETER Path
    File path to validate

    .PARAMETER Operation
    Operation being performed (read, write, delete)
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [string]$Operation = 'write'
    )

    $securityState = Get-PmcSecurityState
    if (-not $securityState.PathWhitelistEnabled) { return $true }

    try {
        # Resolve path to absolute form
        $resolvedPath = $null
        try {
            if ([System.IO.Path]::IsPathRooted($Path)) {
                $resolvedPath = [System.IO.Path]::GetFullPath($Path)
            } else {
                $root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
                $resolvedPath = [System.IO.Path]::GetFullPath((Join-Path $root $Path))
            }
        } catch {
            Write-PmcDebug -Level 1 -Category 'SECURITY' -Message "Path resolution failed: $_" -Data @{ Path = $Path }
            return $false
        }

        # Check against whitelist for write operations
        if ($Operation -eq 'write' -or $Operation -eq 'delete') {
            $allowed = $false
            foreach ($allowedPath in $securityState.AllowedWritePaths) {
                try {
                    $allowedResolved = [System.IO.Path]::GetFullPath($allowedPath)
                    if ($resolvedPath.StartsWith($allowedResolved, [System.StringComparison]::OrdinalIgnoreCase)) {
                        $allowed = $true
                        break
                    }
                } catch {
                    # Size configuration parsing failed - keep default value
                }
            }

            if (-not $allowed) {
                Write-PmcDebug -Level 1 -Category 'SECURITY' -Message "Path not in whitelist" -Data @{ Path = $resolvedPath; Operation = $Operation; AllowedPaths = $securityState.AllowedWritePaths }
                return $false
            }
        }

        # Check for dangerous paths
        $dangerousPaths = @(
            'C:\Windows\System32',
            'C:\Windows\SysWOW64',
            '/etc/',
            '/bin/',
            '/sbin/',
            '/usr/bin/',
            '/usr/sbin/',
            '/boot/',
            '/sys/',
            '/proc/'
        )

        foreach ($dangerousPath in $dangerousPaths) {
            if ($resolvedPath.StartsWith($dangerousPath, [System.StringComparison]::OrdinalIgnoreCase)) {
                Write-PmcDebug -Level 1 -Category 'SECURITY' -Message "Dangerous path detected" -Data @{ Path = $resolvedPath; DangerousPath = $dangerousPath }
                return $false
            }
        }

        # Log audit trail for file operations
        if ($securityState.AuditLoggingEnabled) {
            Write-PmcDebug -Level 2 -Category 'AUDIT' -Message "File operation approved" -Data @{ Path = $resolvedPath; Operation = $Operation; User = $env:USERNAME }
        }

        return $true

    } catch {
        Write-PmcDebug -Level 1 -Category 'SECURITY' -Message "Path safety check error: $_"
        return $false
    }
}

function Invoke-PmcSecureFileOperation {
    <#
    .SYNOPSIS
    Performs file operations with security checks and resource limits

    .PARAMETER Path
    File path for the operation

    .PARAMETER Operation
    Type of operation (read, write, delete)

    .PARAMETER Content
    Content to write (for write operations)

    .PARAMETER ScriptBlock
    Custom operation to perform within security context
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [ValidateSet('read', 'write', 'delete', 'custom')]
        [string]$Operation,

        [string]$Content = '',

        [scriptblock]$ScriptBlock = $null
    )

    # Validate path safety
    if (-not (Test-PmcPathSafety -Path $Path -Operation $Operation)) {
        throw "Path safety validation failed: $Path"
    }

    # Check resource limits
    $securityState = Get-PmcSecurityState
    if ($securityState.ResourceLimitsEnabled) {
        if ($Operation -eq 'write' -and $Content.Length -gt 0) {
            $sizeBytes = [System.Text.Encoding]::UTF8.GetByteCount($Content)
            if ($sizeBytes -gt $securityState.MaxFileSize) {
                throw "Content size ($sizeBytes bytes) exceeds maximum allowed ($($securityState.MaxFileSize) bytes)"
            }
        }

        # Check existing file size for read operations
        if ($Operation -eq 'read' -and (Test-Path $Path)) {
            $fileSize = (Get-Item $Path).Length
            if ($fileSize -gt $securityState.MaxFileSize) {
                throw "File size ($fileSize bytes) exceeds maximum allowed ($($securityState.MaxFileSize) bytes)"
            }
        }
    }

    # Audit log the operation
    if ($securityState.AuditLoggingEnabled) {
        Write-PmcDebug -Level 1 -Category 'AUDIT' -Message "Secure file operation" -Data @{
            Path = $Path
            Operation = $Operation
            ContentSize = $Content.Length
            User = $env:USERNAME
            Timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        }
    }

    try {
        # Perform the operation within timeout
        $result = Measure-PmcOperation -Name "SecureFileOp:$Operation" -Category 'SECURITY' -ScriptBlock {
            switch ($Operation) {
                'read' {
                    return Get-Content -Path $Path -Raw -Encoding UTF8
                }
                'write' {
                    return Set-Content -Path $Path -Value $Content -Encoding UTF8
                }
                'delete' {
                    return Remove-Item -Path $Path -Force
                }
                'custom' {
                    if ($ScriptBlock) {
                        return & $ScriptBlock
                    } else {
                        throw "Custom operation requires ScriptBlock parameter"
                    }
                }
            }
        }

        return $result

    } catch {
        Write-PmcDebug -Level 1 -Category 'SECURITY' -Message "Secure file operation failed: $_" -Data @{ Path = $Path; Operation = $Operation }
        throw
    }
}

function Protect-PmcUserInput {
    <#
    .SYNOPSIS
    Sanitizes user input for safe processing

    .PARAMETER Input
    User input to sanitize

    .PARAMETER AllowHtml
    Whether to allow HTML tags (default: false)
    #>
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Input,

        [bool]$AllowHtml = $false
    )

    try {
        $sanitized = $Input

        # Remove null bytes
        $sanitized = $sanitized -replace "`0", ''

        # Remove Unicode direction overrides
        $sanitized = $sanitized -replace '[\u202A-\u202E\u2066-\u2069]', ''

        # Remove or escape HTML if not allowed
        if (-not $AllowHtml) {
            $sanitized = $sanitized -replace '<', '&lt;'
            $sanitized = $sanitized -replace '>', '&gt;'
            $sanitized = $sanitized -replace '"', '&quot;'
            $sanitized = $sanitized -replace "'", '&#39;'
        }

        # Limit length
        if ($sanitized.Length -gt 10000) {
            $sanitized = $sanitized.Substring(0, 10000)
            Write-PmcDebug -Level 2 -Category 'SECURITY' -Message "Input truncated to 10000 characters"
        }

        Write-PmcDebug -Level 3 -Category 'SECURITY' -Message "Input sanitized" -Data @{
            OriginalLength = $Input.Length
            SanitizedLength = $sanitized.Length
            Modified = ($Input -ne $sanitized)
        }

        return $sanitized

    } catch {
        Write-PmcDebug -Level 1 -Category 'SECURITY' -Message "Input sanitization failed: $_"
        return ""
    }
}

function Test-PmcResourceLimits {
    <#
    .SYNOPSIS
    Checks current resource usage against configured limits

    .DESCRIPTION
    Monitors memory usage, execution time, and other resource constraints
    #>

    $securityState = Get-PmcSecurityState
    if (-not $securityState.ResourceLimitsEnabled) { return $true }

    try {
        # Check memory usage
        $process = Get-Process -Id $PID
        $memoryUsage = $process.WorkingSet64

        if ($memoryUsage -gt $securityState.MaxMemoryUsage) {
            Write-PmcDebug -Level 1 -Category 'SECURITY' -Message "Memory limit exceeded" -Data @{
                CurrentUsage = $memoryUsage
                Limit = $securityState.MaxMemoryUsage
                UsagePercent = [Math]::Round(($memoryUsage / $securityState.MaxMemoryUsage) * 100, 2)
            }
            return $false
        }

        Write-PmcDebug -Level 3 -Category 'SECURITY' -Message "Resource limits check passed" -Data @{
            MemoryUsage = $memoryUsage
            MemoryLimit = $securityState.MaxMemoryUsage
        }

        return $true

    } catch {
        Write-PmcDebug -Level 1 -Category 'SECURITY' -Message "Resource limit check failed: $_"
        return $false
    }
}

function Get-PmcSecurityStatus {
    <#
    .SYNOPSIS
    Returns current security system status and configuration
    #>

    $securityState = Get-PmcSecurityState
    return [PSCustomObject]@{
        InputValidationEnabled = $securityState.InputValidationEnabled
        PathWhitelistEnabled = $securityState.PathWhitelistEnabled
        ResourceLimitsEnabled = $securityState.ResourceLimitsEnabled
        SensitiveDataScanEnabled = $securityState.SensitiveDataScanEnabled
        AuditLoggingEnabled = $securityState.AuditLoggingEnabled
        AllowedWritePaths = $securityState.AllowedWritePaths
        MaxFileSize = $securityState.MaxFileSize
        MaxMemoryUsage = $securityState.MaxMemoryUsage
        MaxExecutionTime = $securityState.MaxExecutionTime
        CurrentMemoryUsage = (Get-Process -Id $PID).WorkingSet64
    }
}

function Set-PmcSecurityLevel {
    <#
    .SYNOPSIS
    Configures security level with predefined profiles

    .PARAMETER Level
    Security level: 'permissive', 'balanced', 'strict'
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateSet('permissive', 'balanced', 'strict')]
        [string]$Level
    )

    switch ($Level) {
        'permissive' {
            Update-PmcStateSection -Section 'Security' -Values @{
                InputValidationEnabled = $false
                PathWhitelistEnabled = $false
                ResourceLimitsEnabled = $false
                SensitiveDataScanEnabled = $false
            }
        }
        'balanced' {
            Update-PmcStateSection -Section 'Security' -Values @{
                InputValidationEnabled = $true
                PathWhitelistEnabled = $true
                ResourceLimitsEnabled = $true
                SensitiveDataScanEnabled = $true
                MaxFileSize = 100MB
                MaxMemoryUsage = 500MB
            }
        }
        'strict' {
            Update-PmcStateSection -Section 'Security' -Values @{
                InputValidationEnabled = $true
                PathWhitelistEnabled = $true
                ResourceLimitsEnabled = $true
                SensitiveDataScanEnabled = $true
                AuditLoggingEnabled = $true
                MaxFileSize = 50MB
                MaxMemoryUsage = 256MB
            }
        }
    }

    Write-PmcDebug -Level 1 -Category 'SECURITY' -Message "Security level changed to: $Level" -Data (Get-PmcSecurityState)
}

function Update-PmcSecurityFromConfig {
    <#
    .SYNOPSIS
    Updates security settings from configuration after config provider is ready
    #>
    try {
        $cfg = Get-PmcConfig
        if ($cfg.Security) {
            if ($cfg.Security.AllowedWritePaths) {
                Set-PmcState -Section 'Security' -Key 'AllowedWritePaths' -Value @($cfg.Security.AllowedWritePaths)
            }
            if ($cfg.Security.MaxFileSize) {
                try {
                    $sizeStr = [string]$cfg.Security.MaxFileSize
                    if ($sizeStr -match '^(\d+)(MB|GB)?$') {
                        $num = [int64]$matches[1]
                        $unit = $matches[2]
                        $bytes = switch ($unit) {
                            'GB' { $num * 1GB }
                            'MB' { $num * 1MB }
                            default { $num }
                        }
                        Set-PmcState -Section 'Security' -Key 'MaxFileSize' -Value $bytes
                    }
                } catch {
                    # Size configuration parsing failed - keep default value
                }
            }
            if ($cfg.Security.MaxMemoryUsage) {
                try {
                    $sizeStr = [string]$cfg.Security.MaxMemoryUsage
                    if ($sizeStr -match '^(\d+)(MB|GB)?$') {
                        $num = [int64]$matches[1]
                        $unit = $matches[2]
                        $bytes = switch ($unit) {
                            'GB' { $num * 1GB }
                            'MB' { $num * 1MB }
                            default { $num }
                        }
                        Set-PmcState -Section 'Security' -Key 'MaxMemoryUsage' -Value $bytes
                    }
                } catch {
                    # Size configuration parsing failed - keep default value
                }
            }
            if ($cfg.Security.RequirePathWhitelist -ne $null) {
                Set-PmcState -Section 'Security' -Key 'PathWhitelistEnabled' -Value ([bool]$cfg.Security.RequirePathWhitelist)
            }
            if ($cfg.Security.ScanForSensitiveData -ne $null) {
                Set-PmcState -Section 'Security' -Key 'SensitiveDataScanEnabled' -Value ([bool]$cfg.Security.ScanForSensitiveData)
            }
            if ($cfg.Security.AuditAllFileOps -ne $null) {
                Set-PmcState -Section 'Security' -Key 'AuditLoggingEnabled' -Value ([bool]$cfg.Security.AuditAllFileOps)
            }
            if ($cfg.Security.AllowTemplateExecution -ne $null) {
                Set-PmcState -Section 'Security' -Key 'TemplateExecutionEnabled' -Value ([bool]$cfg.Security.AllowTemplateExecution)
            }
        }
    } catch {
        Write-PmcDebug -Level 1 -Category 'SECURITY' -Message "Failed to load security config: $_"
    }
}

# Note: Security system is initialized by the root orchestrator after config providers are set

#Export-ModuleMember -Function Initialize-PmcSecuritySystem, Test-PmcInputSafety, Test-PmcPathSafety, Invoke-PmcSecureFileOperation, Protect-PmcUserInput, Test-PmcResourceLimits, Get-PmcSecurityStatus, Set-PmcSecurityLevel, Update-PmcSecurityFromConfig


# END FILE: ./module/Pmc.Strict/src/Security.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/Shortcuts.ps1
# SIZE: 0.8 KB
# MODIFIED: 2025-09-22 15:23:10
# ================================================================================

# Workflow shortcuts

function Invoke-PmcShortcut {
    param([PmcCommandContext]$Context)
    # Use: "# 3" to view item at index 3 from last task list
    if ($Context.FreeText.Count -lt 1) { Write-PmcStyled -Style 'Warning' -Text "Usage: # <index>"; return }
    $tok = $Context.FreeText[0]
    if (-not ($tok -match '^\d+$')) { Write-PmcStyled -Style 'Error' -Text "Invalid index"; return }
    $n = [int]$tok
    $indexMap = Get-PmcLastTaskListMap
    if (-not $indexMap -or -not $indexMap.ContainsKey($n)) {
        Write-PmcStyled -Style 'Warning' -Text "No recent list or index out of range"
        return
    }
    # Delegate to task view
    $ctx = [PmcCommandContext]::new('task','view')
    $ctx.FreeText = @([string]$n)
    Show-PmcTask -Context $ctx
}

#Export-ModuleMember -Function Invoke-PmcShortcut


# END FILE: ./module/Pmc.Strict/src/Shortcuts.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/State.ps1
# SIZE: 16.41 KB
# MODIFIED: 2025-09-23 21:16:35
# ================================================================================

# Centralized State Management for PMC
# Consolidates all scattered script variables into a thread-safe, organized system

Set-StrictMode -Version Latest

# =============================================================================
# CENTRAL STATE CONTAINER
# =============================================================================

# Single master state object containing all global state
$Script:PmcGlobalState = @{
    # System & Core Configuration
    Config = @{
        ProviderGet = { @{} }
        ProviderSet = $null
    }

    # Security System State
    Security = @{
        InputValidationEnabled = $true
        PathWhitelistEnabled = $true
        ResourceLimitsEnabled = $true
        SensitiveDataScanEnabled = $true
        AuditLoggingEnabled = $true
        TemplateExecutionEnabled = $false
        AllowedWritePaths = @()
        MaxFileSize = 100MB
        MaxMemoryUsage = 500MB
        MaxExecutionTime = 300000  # 5 minutes in milliseconds
    }

    # Debug System State
    Debug = @{
        Level = 0                    # 0=off, 1-3=debug levels
        LogPath = 'debug.log'        # Relative to PMC root
        MaxSize = 10MB              # File size before rotation
        RedactSensitive = $true     # Redact sensitive data
        IncludePerformance = $false # Include timing information
        SessionId = (New-Guid).ToString().Substring(0,8)
        StartTime = Get-Date
    }

    # Display / Theme / UI State
    Display = @{
        Theme = @{ PaletteName='default'; Hex='#33aaff'; TrueColor=$true; HighContrast=$false; ColorBlindMode='none' }
        Icons = @{ Mode='emoji' }
        Capabilities = @{ AnsiSupport=$true; TrueColorSupport=$true; IsTTY=$true; NoColor=$false; Platform='unknown' }
        Styles = @{}
    }

    # Help and UI System State
    HelpUI = @{
        # Interactive help browser state
        HelpState = @{
            CurrentCategory = 'All'
            SelectedCommand = 0
            SearchFilter = ''
            ShowExamples = $false
            ViewMode = 'Categories'  # Categories, Commands, Examples, Search
        }
        # Command categories for organized browsing (this will be populated from CommandMap)
        CommandCategories = @{}
    }

    # Interactive Editor State
    Interactive = @{
        Editor = $null              # Will be initialized with PmcEditorState instance
        CompletionCache = @{}       # Completion caching for performance
        CompletionInfoMap = @{}     # Completion info mapping for interactive system
        GhostTextEnabled = $true    # Enable/disable ghost text feature
    }

    # Focus / Context State
    Focus = @{
        Current = 'inbox'
    }

    # Undo/Redo System State
    UndoRedo = @{
        UndoStack = @()
        RedoStack = @()
        MaxUndoSteps = 5
        DataCache = $null           # Cached data for performance
    }

    # Task and Time Mapping State (consolidated from multiple files)
    ViewMappings = @{
        LastTaskListMap = @{}       # Maps display numbers to task IDs
        LastTimeListMap = @{}       # Maps display numbers to time entry IDs
    }

    # Command System State (schemas, maps, metadata)
    Commands = @{
        ParameterMap = @{}          # Parameter schemas from Schemas.ps1
        CommandMap = @{}            # Command mappings from CommandMap.ps1
        ShortcutMap = @{}           # Shortcut mappings from CommandMap.ps1
        CommandMeta = @{}           # Command metadata from CommandMap.ps1
    }

    # State synchronization lock
    _Lock = $false
}

# Convenience: repo root path
function Get-PmcRootPath {
    try {
        return (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent)
    } catch { return (Get-Location).Path }
}

# =============================================================================
# THREAD-SAFE STATE ACCESS FUNCTIONS
# =============================================================================

function Get-PmcState {
    <#
    .SYNOPSIS
    Gets a specific state section or the entire state object

    .PARAMETER Section
    The state section to retrieve (Config, Security, Debug, etc.)

    .PARAMETER Key
    Optional specific key within the section

    .EXAMPLE
    Get-PmcState -Section 'Security'
    Get-PmcState -Section 'Debug' -Key 'Level'
    #>
    [CmdletBinding()]
    param(
        [string]$Section,
        [string]$Key
    )

    # Acquire lock to ensure a consistent read snapshot
    while ($Script:PmcGlobalState._Lock) { Start-Sleep -Milliseconds 1 }
    $Script:PmcGlobalState._Lock = $true

    try {
        if (-not $Section) {
            # Return a shallow clone of the entire state without exposing the lock directly
            $snapshot = @{}
            foreach ($k in $Script:PmcGlobalState.Keys) {
                if ($k -eq '_Lock') { continue }
                $val = $Script:PmcGlobalState[$k]
                if ($val -is [hashtable]) { $snapshot[$k] = $val.Clone() } else { $snapshot[$k] = $val }
            }
            return $snapshot
        }

        if (-not $Script:PmcGlobalState.ContainsKey($Section)) {
            Write-Warning "State section '$Section' does not exist"
            return $null
        }

        $sectionState = $Script:PmcGlobalState[$Section]

        if ($Key) {
            if ($sectionState -is [hashtable] -and $sectionState.ContainsKey($Key)) {
                return $sectionState[$Key]
            } else {
                Write-Warning "State key '$Key' does not exist in section '$Section'"
                return $null
            }
        }

        # Return a copy to avoid external mutation of shared state
        if ($sectionState -is [hashtable]) { return $sectionState.Clone() }
        return $sectionState
    }
    finally {
        $Script:PmcGlobalState._Lock = $false
    }
}

function Set-PmcState {
    <#
    .SYNOPSIS
    Sets a value in the centralized state system

    .PARAMETER Section
    The state section to modify

    .PARAMETER Key
    The key within the section to set

    .PARAMETER Value
    The value to set

    .PARAMETER Merge
    If true, merge hashtable values instead of replacing

    .EXAMPLE
    Set-PmcState -Section 'Debug' -Key 'Level' -Value 2
    Set-PmcState -Section 'Security' -Key 'MaxFileSize' -Value 200MB
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Section,

        [Parameter(Mandatory=$true)]
        [string]$Key,

        [Parameter(Mandatory=$true)]
        $Value,

        [switch]$Merge
    )

    # Acquire lock for thread safety
    while ($Script:PmcGlobalState._Lock) {
        Start-Sleep -Milliseconds 1
    }
    $Script:PmcGlobalState._Lock = $true

    try {
        if (-not $Script:PmcGlobalState.ContainsKey($Section)) {
            Write-Warning "State section '$Section' does not exist"
            return
        }

        $sectionState = $Script:PmcGlobalState[$Section]

        if ($Merge -and $sectionState[$Key] -is [hashtable] -and $Value -is [hashtable]) {
            # Merge hashtables
            foreach ($k in $Value.Keys) {
                $sectionState[$Key][$k] = $Value[$k]
            }
        } else {
            # Direct assignment
            $sectionState[$Key] = $Value
        }

        # Debug logging removed to avoid circular dependency during initialization
    }
    finally {
        $Script:PmcGlobalState._Lock = $false
    }
}

# Convenience helpers for common view mapping state
function Get-PmcLastTaskListMap {
    $map = Get-PmcState -Section 'ViewMappings' -Key 'LastTaskListMap'
    if (-not $map) { $map = @{}; Set-PmcState -Section 'ViewMappings' -Key 'LastTaskListMap' -Value $map }
    return $map
}

function Set-PmcLastTaskListMap {
    param([hashtable]$Map)
    if (-not $Map) { $Map = @{} }
    Set-PmcState -Section 'ViewMappings' -Key 'LastTaskListMap' -Value $Map
}

function Get-PmcLastTimeListMap {
    $map = Get-PmcState -Section 'ViewMappings' -Key 'LastTimeListMap'
    if (-not $map) { $map = @{}; Set-PmcState -Section 'ViewMappings' -Key 'LastTimeListMap' -Value $map }
    return $map
}

function Set-PmcLastTimeListMap {
    param([hashtable]$Map)
    if (-not $Map) { $Map = @{} }
    Set-PmcState -Section 'ViewMappings' -Key 'LastTimeListMap' -Value $Map
}

function Update-PmcStateSection {
    <#
    .SYNOPSIS
    Updates an entire state section

    .PARAMETER Section
    The state section to update

    .PARAMETER Values
    Hashtable of values to update in the section

    .PARAMETER Replace
    If true, replace entire section; if false, merge values

    .EXAMPLE
    Update-PmcStateSection -Section 'Security' -Values @{ MaxFileSize = 200MB; PathWhitelistEnabled = $false }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Section,

        [Parameter(Mandatory=$true)]
        [hashtable]$Values,

        [switch]$Replace
    )

    # Acquire lock for thread safety
    while ($Script:PmcGlobalState._Lock) {
        Start-Sleep -Milliseconds 1
    }
    $Script:PmcGlobalState._Lock = $true

    try {
        if (-not $Script:PmcGlobalState.ContainsKey($Section)) {
            Write-Warning "State section '$Section' does not exist"
            return
        }

        if ($Replace) {
            $Script:PmcGlobalState[$Section] = $Values
        } else {
            foreach ($key in $Values.Keys) {
                $Script:PmcGlobalState[$Section][$key] = $Values[$key]
            }
        }

        # Debug logging removed to avoid circular dependency during initialization
    }
    finally {
        $Script:PmcGlobalState._Lock = $false
    }
}

# =============================================================================
# BACKWARD COMPATIBILITY LAYER
# =============================================================================

# These functions provide backward compatibility for existing code
# They map old script variable access to the new centralized state

function Get-PmcConfigProviders {
    $config = Get-PmcState -Section 'Config'
    return @{
        Get = $config.ProviderGet
        Set = $config.ProviderSet
    }
}

function Set-PmcConfigProviders {
    param($Get, $Set)
    Set-PmcState -Section 'Config' -Key 'ProviderGet' -Value $Get
    if ($Set) {
        Set-PmcState -Section 'Config' -Key 'ProviderSet' -Value $Set
    }
}

function Get-PmcSecurityState {
    return Get-PmcState -Section 'Security'
}

function Get-PmcDebugState {
    return Get-PmcState -Section 'Debug'
}

function Get-PmcHelpState {
    return Get-PmcState -Section 'HelpUI' -Key 'HelpState'
}

function Get-PmcCommandCategories {
    return Get-PmcState -Section 'HelpUI' -Key 'CommandCategories'
}

function Get-PmcTaskListMap {
    return Get-PmcState -Section 'ViewMappings' -Key 'LastTaskListMap'
}

function Set-PmcTaskListMap {
    param([hashtable]$Map)
    Set-PmcState -Section 'ViewMappings' -Key 'LastTaskListMap' -Value $Map
}

function Get-PmcTimeListMap {
    return Get-PmcState -Section 'ViewMappings' -Key 'LastTimeListMap'
}

function Set-PmcTimeListMap {
    param([hashtable]$Map)
    Set-PmcState -Section 'ViewMappings' -Key 'LastTimeListMap' -Value $Map
}

function Get-PmcUndoRedoState {
    return Get-PmcState -Section 'UndoRedo'
}

function Get-PmcInteractiveState {
    return Get-PmcState -Section 'Interactive'
}

function Get-PmcCommandMaps {
    return Get-PmcState -Section 'Commands'
}

# =============================================================================
# STATE INITIALIZATION AND MIGRATION
# =============================================================================

function Initialize-PmcCentralizedState {
    <#
    .SYNOPSIS
    Initializes the centralized state system and migrates existing scattered state
    #>
    [CmdletBinding()]
    param()

    # Debug logging removed to avoid circular dependency during initialization

    # Initialize Interactive Editor if not already done
    if (-not (Get-PmcState -Section 'Interactive' -Key 'Editor')) {
        # Import the PmcEditorState class if it exists
        try {
            $editorState = [PmcEditorState]::new()
            Set-PmcState -Section 'Interactive' -Key 'Editor' -Value $editorState
            # Debug logging removed
        } catch {
            # Debug logging removed
        }
    }

    # Migrate any existing command maps from the old system
    try {
        if (Get-Variable -Name 'PmcCommandMap' -Scope Script -ErrorAction SilentlyContinue) {
            $oldCommandMap = Get-Variable -Name 'PmcCommandMap' -Scope Script -ValueOnly
            Set-PmcState -Section 'Commands' -Key 'CommandMap' -Value $oldCommandMap
            # Debug logging removed
        }

        if (Get-Variable -Name 'PmcParameterMap' -Scope Script -ErrorAction SilentlyContinue) {
            $oldParameterMap = Get-Variable -Name 'PmcParameterMap' -Scope Script -ValueOnly
            Set-PmcState -Section 'Commands' -Key 'ParameterMap' -Value $oldParameterMap
            # Debug logging removed
        }
    } catch {
        # Debug logging removed
    }

    # Debug logging removed
}

function Reset-PmcState {
    <#
    .SYNOPSIS
    Resets the entire state system to defaults (useful for testing)
    #>
    [CmdletBinding()]
    param()

    $Script:PmcGlobalState._Lock = $true
    try {
        # Reset to initial state structure
        $Script:PmcGlobalState = @{
            Config = @{
                ProviderGet = { @{} }
                ProviderSet = $null
            }
            Security = @{
                InputValidationEnabled = $true
                PathWhitelistEnabled = $true
                ResourceLimitsEnabled = $true
                SensitiveDataScanEnabled = $true
                AuditLoggingEnabled = $true
                TemplateExecutionEnabled = $false
                AllowedWritePaths = @()
                MaxFileSize = 100MB
                MaxMemoryUsage = 500MB
                MaxExecutionTime = 300000
            }
            Debug = @{
                Level = 0
                LogPath = 'debug.log'
                MaxSize = 10MB
                RedactSensitive = $true
                IncludePerformance = $false
                SessionId = (New-Guid).ToString().Substring(0,8)
                StartTime = Get-Date
            }
            HelpUI = @{
                HelpState = @{
                    CurrentCategory = 'All'
                    SelectedCommand = 0
                    SearchFilter = ''
                    ShowExamples = $false
                    ViewMode = 'Categories'
                }
                CommandCategories = @{}
            }
            Interactive = @{
                Editor = $null
                CompletionCache = @{}
                GhostTextEnabled = $true
            }
            UndoRedo = @{
                UndoStack = @()
                RedoStack = @()
                MaxUndoSteps = 5
                DataCache = $null
            }
            ViewMappings = @{
                LastTaskListMap = @{}
                LastTimeListMap = @{}
            }
            Commands = @{
                ParameterMap = @{}
                CommandMap = @{}
                ShortcutMap = @{}
                CommandMeta = @{}
            }
            _Lock = $false
        }

        # Debug logging removed
    }
    finally {
        $Script:PmcGlobalState._Lock = $false
    }
}

function Get-PmcStateSnapshot {
    <#
    .SYNOPSIS
    Gets a snapshot of the current state for debugging or backup purposes
    #>
    [CmdletBinding()]
    param()

    # Create a deep copy of the state (excluding the lock)
    $snapshot = @{}
    foreach ($section in $Script:PmcGlobalState.Keys) {
        if ($section -ne '_Lock') {
            $snapshot[$section] = $Script:PmcGlobalState[$section].Clone()
        }
    }

    return $snapshot
}

# =============================================================================
# MODULE INITIALIZATION
# =============================================================================

# Auto-initialize the state system when this module is loaded
Initialize-PmcCentralizedState

# Debug logging removed to avoid circular dependency during initialization

Export-ModuleMember -Function Get-PmcRootPath, Get-PmcState, Set-PmcState, Get-PmcLastTaskListMap, Set-PmcLastTaskListMap, Get-PmcLastTimeListMap, Set-PmcLastTimeListMap, Update-PmcStateSection, Get-PmcConfigProviders, Set-PmcConfigProviders, Get-PmcSecurityState, Get-PmcDebugState, Get-PmcHelpState, Get-PmcCommandCategories, Get-PmcTaskListMap, Set-PmcTaskListMap, Get-PmcTimeListMap, Set-PmcTimeListMap, Get-PmcUndoRedoState, Get-PmcInteractiveState, Get-PmcCommandMaps, Initialize-PmcCentralizedState, Reset-PmcState, Get-PmcStateSnapshot


# END FILE: ./module/Pmc.Strict/src/State.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/Storage.ps1
# SIZE: 21.98 KB
# MODIFIED: 2025-09-24 04:57:52
# ================================================================================

# Storage and schema for strict engine (self-contained)

Set-StrictMode -Version Latest

function Add-PmcUndoEntry {
    param(
        [string]$file,
        [object]$data
    )

    # Create undo entry for the current data state before modification
    try {
        if (-not (Test-Path $file)) {
            # No existing file to backup
            return
        }

        $undoFile = $file + '.undo'
        $currentContent = Get-Content $file -Raw -ErrorAction SilentlyContinue

        if ($currentContent) {
            # Save current state for undo capability
            $undoEntry = @{
                timestamp = (Get-Date).ToString('o')
                file = $file
                content = $currentContent
            }

            $undoJson = $undoEntry | ConvertTo-Json -Compress
            Add-Content -Path $undoFile -Value $undoJson -ErrorAction SilentlyContinue

            # Keep only last 3 undo entries to prevent file growth
            $undoLines = Get-Content $undoFile -ErrorAction SilentlyContinue
            if ($undoLines -and $undoLines.Count -gt 3) {
                $undoLines[-3..-1] | Set-Content $undoFile -ErrorAction SilentlyContinue
            }
        }
    } catch {
        # Undo functionality is non-critical, don't fail the main operation
        Write-PmcDebug -Level 2 -Category 'STORAGE' -Message "Undo entry creation failed: $_"
    }
}

function Get-PmcTaskFilePath {
    $cfg = Get-PmcConfig
    $path = $null
    try { if ($cfg.Paths -and $cfg.Paths.TaskFile) { $path = [string]$cfg.Paths.TaskFile } } catch {
        # Configuration access failed - use default path
    }
    if (-not $path -or [string]::IsNullOrWhiteSpace($path)) {
        # Default to pmc/tasks.json (three levels up from module dir)
        $root = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
        $path = Join-Path $root 'tasks.json'
    }
    return $path
}

function Initialize-PmcDataSchema {
    param($data)
    if (-not $data) { return $data }
    if (-not $data.PSObject.Properties['schema_version']) { $data | Add-Member -NotePropertyName schema_version -NotePropertyValue 1 -Force }
    foreach ($k in @('tasks','deleted','completed','projects','timelogs','activityLog','templates','recurringTemplates','aliases')) {
        if (-not $data.PSObject.Properties[$k] -or -not $data.$k) { $data | Add-Member -NotePropertyName $k -NotePropertyValue @() -Force }
    }
    # Normalize aliases to hashtable for reliable access
    try {
        if ($data.PSObject.Properties['aliases']) {
            $al = $data.aliases
            if ($al -is [pscustomobject]) {
                $ht = @{}
                foreach ($p in $al.PSObject.Properties) { $ht[$p.Name] = $p.Value }
                $data.aliases = $ht
            } elseif ($al -is [array]) {
                # Convert array of pairs into hashtable if possible
                $ht = @{}
                foreach ($item in $al) { try { $ht[$item.Name] = $item.Value } catch {
                    # Array item property access failed - skip this item
                } }
                $data.aliases = $ht
            } elseif (-not ($al -is [hashtable])) {
                $data.aliases = @{}
            }
        } else {
            $data | Add-Member -NotePropertyName aliases -NotePropertyValue @{} -Force
        }
    } catch {
        # Data schema normalization failed - continue with what we have
    }
    if (-not $data.PSObject.Properties['currentContext'] -or -not $data.currentContext) { $data | Add-Member -NotePropertyName currentContext -NotePropertyValue 'inbox' -Force }
    if (-not $data.PSObject.Properties['preferences']) { $data | Add-Member -NotePropertyName preferences -NotePropertyValue @{ autoBackup = $true } -Force }

    # Normalize task properties to prevent "property cannot be found" errors
    if ($data.tasks -and $data.tasks.Count -gt 0) {
        foreach ($task in $data.tasks) {
            if ($null -eq $task) { continue }
            try {
                # Ensure critical properties exist with defaults
                if (-not (Pmc-HasProp $task 'depends')) { Add-Member -InputObject $task -MemberType NoteProperty -Name 'depends' -NotePropertyValue @() -Force }
                if (-not (Pmc-HasProp $task 'tags')) { Add-Member -InputObject $task -MemberType NoteProperty -Name 'tags' -NotePropertyValue @() -Force }
                if (-not (Pmc-HasProp $task 'notes')) { Add-Member -InputObject $task -MemberType NoteProperty -Name 'notes' -NotePropertyValue @() -Force }
                if (-not (Pmc-HasProp $task 'recur')) { Add-Member -InputObject $task -MemberType NoteProperty -Name 'recur' -NotePropertyValue $null -Force }
                if (-not (Pmc-HasProp $task 'estimatedMinutes')) { Add-Member -InputObject $task -MemberType NoteProperty -Name 'estimatedMinutes' -NotePropertyValue $null -Force }
                if (-not (Pmc-HasProp $task 'status')) { Add-Member -InputObject $task -MemberType NoteProperty -Name 'status' -NotePropertyValue 'pending' -Force }
                if (-not (Pmc-HasProp $task 'priority')) { Add-Member -InputObject $task -MemberType NoteProperty -Name 'priority' -NotePropertyValue 0 -Force }
                if (-not (Pmc-HasProp $task 'project')) { Add-Member -InputObject $task -MemberType NoteProperty -Name 'project' -NotePropertyValue 'inbox' -Force }
                if (-not (Pmc-HasProp $task 'due')) { Add-Member -InputObject $task -MemberType NoteProperty -Name 'due' -NotePropertyValue $null -Force }
                if (-not (Pmc-HasProp $task 'nextSuggestedCount')) { Add-Member -InputObject $task -MemberType NoteProperty -Name 'nextSuggestedCount' -NotePropertyValue 3 -Force }
                if (-not (Pmc-HasProp $task 'lastNextShown')) { Add-Member -InputObject $task -MemberType NoteProperty -Name 'lastNextShown' -NotePropertyValue (Get-Date).ToString('yyyy-MM-dd') -Force }
                if (-not (Pmc-HasProp $task 'created')) { Add-Member -InputObject $task -MemberType NoteProperty -Name 'created' -NotePropertyValue (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') -Force }
            } catch {
                # Individual task property normalization failed - continue
            }
        }
    }
    # Ensure timelog entries have taskId (optional linkage to tasks)
    if ($data.timelogs -and $data.timelogs.Count -gt 0) {
        foreach ($log in $data.timelogs) {
            if ($null -eq $log) { continue }
            if (-not (Pmc-HasProp $log 'taskId')) {
                try { Add-Member -InputObject $log -MemberType NoteProperty -Name 'taskId' -NotePropertyValue $null -Force } catch {}
            }
        }
    }

    # Normalize project properties
    if ($data.projects -and $data.projects.Count -gt 0) {
        foreach ($project in $data.projects) {
            if ($null -eq $project) { continue }
            try {
                if (-not (Pmc-HasProp $project 'name')) { Add-Member -InputObject $project -MemberType NoteProperty -Name 'name' -NotePropertyValue '' -Force }
                if (-not (Pmc-HasProp $project 'description')) { Add-Member -InputObject $project -MemberType NoteProperty -Name 'description' -NotePropertyValue '' -Force }
                if (-not (Pmc-HasProp $project 'aliases')) { Add-Member -InputObject $project -MemberType NoteProperty -Name 'aliases' -NotePropertyValue @() -Force }
                if (-not (Pmc-HasProp $project 'created')) { Add-Member -InputObject $project -MemberType NoteProperty -Name 'created' -NotePropertyValue (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') -Force }
                if (-not (Pmc-HasProp $project 'isArchived')) { Add-Member -InputObject $project -MemberType NoteProperty -Name 'isArchived' -NotePropertyValue $false -Force }
                if (-not (Pmc-HasProp $project 'color')) { Add-Member -InputObject $project -MemberType NoteProperty -Name 'color' -NotePropertyValue 'Gray' -Force }
                if (-not (Pmc-HasProp $project 'icon')) { Add-Member -InputObject $project -MemberType NoteProperty -Name 'icon' -NotePropertyValue '📁' -Force }
                if (-not (Pmc-HasProp $project 'sortOrder')) { Add-Member -InputObject $project -MemberType NoteProperty -Name 'sortOrder' -NotePropertyValue 0 -Force }
                # Extended fields (t2 parity)
                if (-not (Pmc-HasProp $project 'ID1')) { Add-Member -InputObject $project -MemberType NoteProperty -Name 'ID1' -NotePropertyValue '' -Force }
                if (-not (Pmc-HasProp $project 'ID2')) { Add-Member -InputObject $project -MemberType NoteProperty -Name 'ID2' -NotePropertyValue '' -Force }
                if (-not (Pmc-HasProp $project 'ProjFolder')) { Add-Member -InputObject $project -MemberType NoteProperty -Name 'ProjFolder' -NotePropertyValue '' -Force }
                if (-not (Pmc-HasProp $project 'AssignedDate')) { Add-Member -InputObject $project -MemberType NoteProperty -Name 'AssignedDate' -NotePropertyValue '' -Force }
                if (-not (Pmc-HasProp $project 'DueDate')) { Add-Member -InputObject $project -MemberType NoteProperty -Name 'DueDate' -NotePropertyValue '' -Force }
                if (-not (Pmc-HasProp $project 'BFDate')) { Add-Member -InputObject $project -MemberType NoteProperty -Name 'BFDate' -NotePropertyValue '' -Force }
                if (-not (Pmc-HasProp $project 'CAAName')) { Add-Member -InputObject $project -MemberType NoteProperty -Name 'CAAName' -NotePropertyValue '' -Force }
                if (-not (Pmc-HasProp $project 'RequestName')) { Add-Member -InputObject $project -MemberType NoteProperty -Name 'RequestName' -NotePropertyValue '' -Force }
                if (-not (Pmc-HasProp $project 'T2020')) { Add-Member -InputObject $project -MemberType NoteProperty -Name 'T2020' -NotePropertyValue '' -Force }
            } catch {
                # Individual project property normalization failed - continue
            }
        }
    }

    return $data
}

# Normalize data to consistent shapes (fail-fast for irrecoverable cases)
function Normalize-PmcData {
    param($data)
    if (-not $data) { throw 'Data is null' }
    foreach ($k in @('tasks','deleted','completed','projects','timelogs','activityLog','templates','recurringTemplates')) {
        if (-not (Pmc-HasProp $data $k) -or -not $data.$k) { $data | Add-Member -NotePropertyName $k -NotePropertyValue @() -Force }
        elseif (-not ($data.$k -is [System.Collections.IEnumerable])) { throw "Data section '$k' is not a list" }
    }
    # Coerce hashtable entries to PSCustomObject for tasks/projects/timelogs
    $coerce = {
        param($arrRef)
        $new = @()
        foreach ($it in @($arrRef)) {
            if ($null -eq $it) { continue }
            if ($it -is [hashtable]) { $new += [pscustomobject]$it }
            else { $new += $it }
        }
        return ,$new
    }
    $data.tasks = & $coerce $data.tasks
    $data.projects = & $coerce $data.projects
    $data.timelogs = & $coerce $data.timelogs
    return $data
}

# Alias for backward compatibility
function Get-PmcAllData {
    return Get-PmcData
}

# Data provider for display system
function Get-PmcDataProvider {
    param([string]$ProviderType = 'Storage')

    # Return an object with GetData method
    return [PSCustomObject]@{
        GetData = { Get-PmcData }
    }
}

# Alias for backward compatibility - critical for Tasks/Time/Projects
function Set-PmcAllData {
    param($Data)
    Save-PmcData -Data $Data
}

function Get-PmcData {
    $file = Get-PmcTaskFilePath
    if (-not (Test-Path $file)) {
        $root = Split-Path $file -Parent
        try { if (-not (Test-Path $root)) { New-Item -ItemType Directory -Path $root -Force | Out-Null } } catch {
            # Directory creation failed - may cause subsequent save failures
        }
        $init = @{
            tasks=@(); deleted=@(); completed=@(); timelogs=@(); activityLog=@(); projects=@(@{ name='inbox'; description='Default inbox'; aliases=@(); created=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss') });
            currentContext='inbox'; schema_version=1; preferences=@{ autoBackup=$true }
        } | ConvertTo-Json -Depth 10
        $init | Set-Content -Path $file -Encoding UTF8
    }
    # Load with optional strict recovery policy
    $cfg = Get-PmcConfig; $strict = $true; try { if ($cfg.Behavior -and $cfg.Behavior.StrictDataMode -ne $null) { $strict = [bool]$cfg.Behavior.StrictDataMode } } catch {}
    try {
        $raw = Get-Content $file -Raw
        $data = $raw | ConvertFrom-Json
        # Coerce collections before adding default properties to ensure NoteProperty attaches to PSCustomObject
        $data = Normalize-PmcData $data
        $data = Initialize-PmcDataSchema $data
        return $data
    } catch {
        if ($strict) { throw }
        # Non-strict: Try .tmp
        $tmp = "$file.tmp"
        try {
            if (Test-Path $tmp) {
                $raw = Get-Content $tmp -Raw
                $data = $raw | ConvertFrom-Json
                Write-PmcDebug -Level 1 -Category 'STORAGE' -Message 'Recovered data from tmp'
                return (Initialize-PmcDataSchema $data)
            }
        } catch {
            # Temporary file recovery failed - try backup files
        }
        # Try rotating backups .bak1..bak9
        for ($i=1; $i -le 9; $i++) {
            $bak = "$file.bak$i"
            if (-not (Test-Path $bak)) { continue }
            try {
                $raw = Get-Content $bak -Raw
                $data = $raw | ConvertFrom-Json
                Write-PmcDebug -Level 1 -Category 'STORAGE' -Message ("Recovered data from backup: {0}" -f (Split-Path $bak -Leaf))
                return (Initialize-PmcDataSchema $data)
            } catch {
                # Backup file recovery failed - try next backup
            }
        }
        throw "Failed to load or recover data"
    }
}

function Get-PmcSafePath {
    param([string]$Path)
    $cfg = Get-PmcConfig
    $strict = $true; $allowed=@()
    try { if ($cfg.Behavior -and $cfg.Behavior.SafePathsStrict -ne $null) { $strict = [bool]$cfg.Behavior.SafePathsStrict } } catch {
        # Configuration access failed - use default strict mode
    }
    try { if ($cfg.Paths -and $cfg.Paths.AllowedWriteDirs) { $allowed = @($cfg.Paths.AllowedWriteDirs) } } catch {
        # Configuration access failed - use empty allowed paths list
    }
    $root = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent
    if ([string]::IsNullOrWhiteSpace($Path)) { return (Join-Path $root 'output.txt') }
    try {
        $baseFull = [System.IO.Path]::GetFullPath($root)
        $isAbs = [System.IO.Path]::IsPathRooted($Path)
        if (-not $isAbs) {
            $combined = Join-Path $root $Path
            $full = [System.IO.Path]::GetFullPath($combined)
            if (-not $full.StartsWith($baseFull, [System.StringComparison]::OrdinalIgnoreCase)) {
                return (Join-Path $baseFull ([System.IO.Path]::GetFileName($Path)))
            }
            return $full
        }
        # Absolute path
        $fullAbs = [System.IO.Path]::GetFullPath($Path)
        if ($fullAbs.StartsWith($baseFull, [System.StringComparison]::OrdinalIgnoreCase)) { return $fullAbs }
        if (-not $strict) { return $fullAbs }
        foreach ($dir in $allowed) {
            if ([string]::IsNullOrWhiteSpace($dir)) { continue }
            # Allowlist entries are relative to base unless absolute
            $dirFull = if ([System.IO.Path]::IsPathRooted($dir)) { [System.IO.Path]::GetFullPath($dir) } else { [System.IO.Path]::GetFullPath((Join-Path $root $dir)) }
            if ($fullAbs.StartsWith($dirFull, [System.StringComparison]::OrdinalIgnoreCase)) { return $fullAbs }
        }
        return (Join-Path $baseFull ([System.IO.Path]::GetFileName($Path)))
    } catch {
        return (Join-Path $root ([System.IO.Path]::GetFileName($Path)))
    }
}

function Lock-PmcFile {
    param([string]$file)
    $lockPath = $file + '.lock'
    $maxRetries = 20; $delay = 100
    for ($i=0; $i -lt $maxRetries; $i++) {
        try { return [System.IO.File]::Open($lockPath, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None) } catch {
            # File lock acquisition failed - will retry
        }
        try { $info = Get-Item $lockPath -ErrorAction SilentlyContinue; if ($info -and ((Get-Date) - $info.LastWriteTime).TotalMinutes -gt 2) { Remove-Item $lockPath -Force -ErrorAction SilentlyContinue } } catch {
            # Stale lock cleanup failed - continue trying
        }
        Start-Sleep -Milliseconds $delay
    }
    throw "Could not acquire lock for $file"
}

function Unlock-PmcFile { param($lock,$file) try { if ($lock) { $lock.Close() } } catch {
        # Lock file close failed - file handle may remain open
    } ; try { Remove-Item ($file + '.lock') -Force -ErrorAction SilentlyContinue } catch {
        # Lock file removal failed - may cause future lock conflicts
    } }

function Invoke-PmcBackupRotation {
    param([string]$file,[int]$count=3)
    # Make backup retention configurable via Behavior.MaxBackups
    try { $cfg=Get-PmcConfig; if ($cfg.Behavior -and $cfg.Behavior.MaxBackups) { $count = [int]$cfg.Behavior.MaxBackups } } catch {
        # Configuration access failed - use default backup count
    }
    for ($i=$count-1; $i -ge 1; $i--) {
        $src = "$file.bak$i"; $dst = "$file.bak$($i+1)"; if (Test-Path $src) { Move-Item -Force $src $dst }
    }
    if (Test-Path $file) { Copy-Item $file "$file.bak1" -Force }
}

function Add-PmcUndoState {
    param([string]$file,[object]$data)
    $undoFile = $file + '.undo'
    $stack = @(); if (Test-Path $undoFile) { try { $stack = Get-Content $undoFile -Raw | ConvertFrom-Json } catch { $stack=@() } }
    $stack += ($data | ConvertTo-Json -Depth 10)
    $max = 10; try { $cfg=Get-PmcConfig; if ($cfg.Behavior -and $cfg.Behavior.MaxUndoLevels) { $max = [int]$cfg.Behavior.MaxUndoLevels } } catch {
        # Configuration access failed - use default undo levels
    }
    if (@($stack).Count -gt $max) { $stack = $stack[-$max..-1] }
    $stack | ConvertTo-Json -Depth 10 | Set-Content $undoFile -Encoding UTF8
}

function Get-PmcUndoRedoStacks {
    param([string]$file)
    $undoFile = $file + '.undo'
    $redoFile = $file + '.redo'
    $undo = @(); $redo = @()
    if (Test-Path $undoFile) { try { $undo = Get-Content $undoFile -Raw | ConvertFrom-Json } catch { $undo=@() } }
    if (Test-Path $redoFile) { try { $redo = Get-Content $redoFile -Raw | ConvertFrom-Json } catch { $redo=@() } }
    return @{ undo=$undo; redo=$redo; undoFile=$undoFile; redoFile=$redoFile }
}

function Save-PmcUndoRedoStacks {
    param([array]$Undo,[array]$Redo,[string]$UndoFile,[string]$RedoFile)
    try { $Undo | ConvertTo-Json -Depth 10 | Set-Content $UndoFile -Encoding UTF8 } catch {
        # Undo stack save failed - undo functionality may be impaired
    }
    try { $Redo | ConvertTo-Json -Depth 10 | Set-Content $RedoFile -Encoding UTF8 } catch {
        # Redo stack save failed - redo functionality may be impaired
    }
}

function Add-PmcActivity {
    param([object]$data,[string]$action)
    if (-not $data.PSObject.Properties['activityLog']) { $data | Add-Member -NotePropertyName activityLog -NotePropertyValue @() -Force }
    $data.activityLog += @{ timestamp=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss'); action=$action; user=$env:USERNAME }
    if (@($data.activityLog).Count -gt 1000) { $data.activityLog = $data.activityLog[-1000..-1] }
}

function Save-PmcData {
    param(
        [Parameter(Mandatory=$true)][object]$data,
        [string]$Action=''
    )

    # Check resource limits before proceeding
    if (-not (Test-PmcResourceLimits)) {
        throw "Resource limits exceeded - cannot save data"
    }

    $cfg = Get-PmcConfig; $whatIf=$false; try { if ($cfg.Behavior -and $cfg.Behavior.WhatIf) { $whatIf = [bool]$cfg.Behavior.WhatIf } } catch {
        # Configuration access failed - whatIf remains false
    }
    if ($whatIf) { Write-Host 'WhatIf: changes not saved' -ForegroundColor DarkYellow; return }

    $file = Get-PmcTaskFilePath

    # Validate file path security
    if (-not (Test-PmcPathSafety -Path $file -Operation 'write')) {
        throw "Path safety validation failed for: $file"
    }

    Write-PmcDebugStorage -Operation 'SaveData' -File $file -Data @{ Action = $Action; WhatIf = $whatIf }

    $lock = $null
    try {
        $lock = Lock-PmcFile $file

        Write-PmcDebugStorage -Operation 'AcquiredLock' -File $file

        Invoke-PmcBackupRotation -file $file -count 3
        Add-PmcUndoEntry -file $file -data $data
        if ($Action) { Add-PmcActivity -data $data -action $Action }

        $tmp = "$file.tmp"

        # Use secure file operation for the actual write
        $jsonContent = $data | ConvertTo-Json -Depth 10

        # Validate content safety
        if (-not (Test-PmcInputSafety -Input $jsonContent -InputType 'json')) {
            Write-PmcDebug -Level 1 -Category 'SECURITY' -Message "Data content failed safety validation"
        }

        Invoke-PmcSecureFileOperation -Path $tmp -Operation 'write' -Content $jsonContent

        Move-Item -Force -Path $tmp -Destination $file
        if (Test-Path $tmp) { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }

        Write-PmcDebugStorage -Operation 'SaveCompleted' -File $file -Data @{ Size = $jsonContent.Length }

    } catch {
        Write-PmcDebugStorage -Operation 'SaveFailed' -File $file -Data @{ Error = $_.ToString() }
        Write-Host "Failed to save data: $_" -ForegroundColor Red
        throw
    } finally {
        Unlock-PmcFile $lock $file
    }
}

function Get-PmcDataAlias { return Get-PmcData }

function Get-PmcNextTaskId {
    param($data)
    try { $ids = @($data.tasks | ForEach-Object { try { [int]$_.id } catch { 0 } }); $max = ($ids | Measure-Object -Maximum).Maximum; return ([int]$max + 1) } catch { return 1 }
}

function Get-PmcNextTimeLogId {
    param($data)
    try { $ids = @($data.timelogs | ForEach-Object { try { [int]$_.id } catch { 0 } }); $max = ($ids | Measure-Object -Maximum).Maximum; return ([int]$max + 1) } catch { return 1 }
}

Export-ModuleMember -Function Add-PmcUndoEntry, Get-PmcTaskFilePath, Initialize-PmcDataSchema, Normalize-PmcData, Get-PmcData, Get-PmcAllData, Get-PmcDataProvider, Get-PmcDataAlias, Get-PmcSafePath, Lock-PmcFile, Unlock-PmcFile, Invoke-PmcBackupRotation, Add-PmcUndoState, Save-PmcData, Set-PmcAllData


# END FILE: ./module/Pmc.Strict/src/Storage.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/TaskEditor.ps1
# SIZE: 16.7 KB
# MODIFIED: 2025-09-22 17:43:07
# ================================================================================

# TaskEditor.ps1 - Interactive task editing with full-screen editor
# Provides rich editing experience for PMC tasks with multi-line support and metadata editing

class PmcTaskEditor {
    [string]$TaskId
    [hashtable]$TaskData
    [string[]]$DescriptionLines
    [string]$Project
    [string]$Priority
    [string]$DueDate
    [string[]]$Tags
    [int]$CurrentLine
    [int]$CursorColumn
    [bool]$IsEditing
    [string]$Mode  # 'description', 'metadata', 'preview'
    [hashtable]$OriginalData
    [int]$StartRow
    [int]$EndRow

    PmcTaskEditor([string]$taskId) {
        $this.TaskId = $taskId
        $this.LoadTask()
        $this.InitializeEditor()
    }

    [void] LoadTask() {
        try {
            # Load task data from PMC data store
            $taskDataResult = Invoke-PmcCommand "task show $($this.TaskId)" -Raw

            if (-not $taskDataResult) {
                throw "Task $($this.TaskId) not found"
            }

            $this.TaskData = $taskDataResult
            $this.OriginalData = $taskDataResult.Clone()

            # Parse task fields
            $this.DescriptionLines = @($taskDataResult.description -split "`n")
            $this.Project = if ($taskDataResult.project) { $taskDataResult.project } else { "" }
            $this.Priority = if ($taskDataResult.priority) { $taskDataResult.priority } else { "" }
            $this.DueDate = if ($taskDataResult.due) { $taskDataResult.due } else { "" }
            $this.Tags = @((if ($taskDataResult.tags) { $taskDataResult.tags } else { @() }))

        } catch {
            throw "Failed to load task: $_"
        }
    }

    [void] InitializeEditor() {
        $this.CurrentLine = 0
        $this.CursorColumn = 0
        $this.IsEditing = $false
        $this.Mode = 'description'

        # Calculate screen regions
        $this.StartRow = 3
        $this.EndRow = [PmcTerminalService]::GetHeight() - 8
    }

    [void] Show() {
        try {
            # Clear screen and setup editor
            [Console]::Clear()
            $this.DrawHeader()
            $this.DrawTaskContent()
            $this.DrawFooter()
            $this.DrawStatusLine()

            # Start editor loop
            $this.EditorLoop()

        } catch {
            Write-PmcStyled -Style 'Error' -Text ("Editor error: {0}" -f $_)
        } finally {
            # Restore normal screen
            [Console]::Clear()
        }
    }

    [void] DrawHeader() {
        $palette = Get-PmcColorPalette
        $headerColor = Get-PmcColorSequence $palette.Header
        $resetColor = [PmcVT]::Reset()

        [Console]::SetCursorPosition(0, 0)
        $title = "PMC Task Editor - Task #$($this.TaskId)"
        $separator = "═" * [PmcTerminalService]::GetWidth()

        Write-Host "$headerColor$title$resetColor"
        Write-Host "$headerColor$separator$resetColor"
        Write-Host ""
    }

    [void] DrawTaskContent() {
        $startRowPos = $this.StartRow

        # Mode indicator
        $modeIndicator = switch ($this.Mode) {
            'description' { "[F1] Description Editor" }
            'metadata' { "[F2] Metadata Editor" }
            'preview' { "[F3] Preview Mode" }
        }

        [Console]::SetCursorPosition(0, $startRowPos - 1)
        Write-PmcStyled -Style 'Warning' -Text $modeIndicator

        switch ($this.Mode) {
            'description' { $this.DrawDescriptionEditor($startRowPos) }
            'metadata' { $this.DrawMetadataEditor($startRowPos) }
            'preview' { $this.DrawPreviewMode($startRowPos) }
        }
    }

    [void] DrawDescriptionEditor([int]$startRow) {
        $palette = Get-PmcColorPalette
        $textColor = Get-PmcColorSequence $palette.Text
        $resetColor = [PmcVT]::Reset()
        $cursorColor = Get-PmcColorSequence $palette.Cursor

        # Clear content area
        for ($i = $startRow; $i -le $this.EndRow; $i++) {
            [Console]::SetCursorPosition(0, $i)
            Write-Host (' ' * [PmcTerminalService]::GetWidth()) -NoNewline
        }

        # Draw description lines
        $maxLines = $this.EndRow - $startRow + 1
        $visibleLines = [Math]::Min($this.DescriptionLines.Count, $maxLines)

        for ($i = 0; $i -lt $visibleLines; $i++) {
            [Console]::SetCursorPosition(0, $startRow + $i)

            $line = $this.DescriptionLines[$i]
            $lineNumber = ($i + 1).ToString().PadLeft(3)

            if ($i -eq $this.CurrentLine) {
                # Highlight current line
                Write-Host "$cursorColor$lineNumber │ $line$resetColor" -NoNewline
            } else {
                Write-Host "$textColor$lineNumber │ $line$resetColor" -NoNewline
            }
        }

        # Show cursor position
        if ($this.CurrentLine -lt $visibleLines) {
            $cursorRow = $startRow + $this.CurrentLine
            $cursorCol = 6 + $this.CursorColumn  # Account for line number prefix
            [Console]::SetCursorPosition($cursorCol, $cursorRow)
        }
    }

    [void] DrawMetadataEditor([int]$startRow) {
        $palette = Get-PmcColorPalette
        $labelColor = Get-PmcColorSequence $palette.Label
        $valueColor = Get-PmcColorSequence $palette.Text
        $resetColor = [PmcVT]::Reset()

        # Clear area
        for ($i = $startRow; $i -le $this.EndRow; $i++) {
            [Console]::SetCursorPosition(0, $i)
            Write-Host (' ' * [PmcTerminalService]::GetWidth()) -NoNewline
        }

        $row = $startRow

        # Project field
        [Console]::SetCursorPosition(0, $row++)
        Write-Host "$labelColor  Project:$resetColor $valueColor$($this.Project)$resetColor"

        # Priority field
        [Console]::SetCursorPosition(0, $row++)
        Write-Host "$labelColor Priority:$resetColor $valueColor$($this.Priority)$resetColor"

        # Due date field
        [Console]::SetCursorPosition(0, $row++)
        Write-Host "$labelColor Due Date:$resetColor $valueColor$($this.DueDate)$resetColor"

        # Tags field
        [Console]::SetCursorPosition(0, $row++)
        $tagsStr = if ($this.Tags.Count -gt 0) { $this.Tags -join ", " } else { "(none)" }
        Write-Host "$labelColor     Tags:$resetColor $valueColor$tagsStr$resetColor"

        $row++

        # Metadata editing instructions
        [Console]::SetCursorPosition(0, $row)
        Write-PmcStyled -Style 'Muted' -Text "Press Enter to edit a field, Tab/Shift+Tab to navigate"
    }

    [void] DrawPreviewMode([int]$startRow) {
        $palette = Get-PmcColorPalette
        $headerColor = Get-PmcColorSequence $palette.Header
        $textColor = Get-PmcColorSequence $palette.Text
        $metaColor = Get-PmcColorSequence $palette.Muted
        $resetColor = [PmcVT]::Reset()

        # Clear area
        for ($i = $startRow; $i -le $this.EndRow; $i++) {
            [Console]::SetCursorPosition(0, $i)
            Write-Host (' ' * [PmcTerminalService]::GetWidth()) -NoNewline
        }

        $row = $startRow

        # Task header
        [Console]::SetCursorPosition(0, $row++)
        Write-Host "$headerColor╭─ Task Preview ─────────────────────────$resetColor"

        # Description
        [Console]::SetCursorPosition(0, $row++)
        Write-Host "$textColor│ Description:$resetColor"

        foreach ($line in $this.DescriptionLines) {
            [Console]::SetCursorPosition(0, $row++)
            Write-Host "$textColor│   $line$resetColor"
        }

        # Metadata
        [Console]::SetCursorPosition(0, $row++)
        Write-Host "$textColor│$resetColor"
        [Console]::SetCursorPosition(0, $row++)
        Write-Host "$textColor│ Metadata:$resetColor"
        [Console]::SetCursorPosition(0, $row++)
        Write-Host "$metaColor│   Project: $($this.Project)$resetColor"
        [Console]::SetCursorPosition(0, $row++)
        Write-Host "$metaColor│   Priority: $($this.Priority)$resetColor"
        [Console]::SetCursorPosition(0, $row++)
        Write-Host "$metaColor│   Due: $($this.DueDate)$resetColor"
        [Console]::SetCursorPosition(0, $row++)
        Write-Host "$metaColor│   Tags: $($this.Tags -join ', ')$resetColor"

        [Console]::SetCursorPosition(0, $row++)
        Write-Host "$headerColor╰────────────────────────────────────────$resetColor"
    }

    [void] DrawFooter() {
        $footerRow = [PmcTerminalService]::GetHeight() - 4
        $palette = Get-PmcColorPalette
        $footerColor = Get-PmcColorSequence $palette.Footer
        $resetColor = [PmcVT]::Reset()

        [Console]::SetCursorPosition(0, $footerRow)
        Write-Host "$footerColor$('─' * [PmcTerminalService]::GetWidth())$resetColor"

        [Console]::SetCursorPosition(0, $footerRow + 1)
        Write-Host "$footerColor F1:Description  F2:Metadata  F3:Preview  Ctrl+S:Save  Esc:Cancel$resetColor"
    }

    [void] DrawStatusLine() {
        $statusRow = [PmcTerminalService]::GetHeight() - 2
        $palette = Get-PmcColorPalette
        $statusColor = Get-PmcColorSequence $palette.Status
        $resetColor = [PmcVT]::Reset()

        [Console]::SetCursorPosition(0, $statusRow)

        $status = switch ($this.Mode) {
            'description' { "Line $($this.CurrentLine + 1), Column $($this.CursorColumn + 1)" }
            'metadata' { "Metadata Editor - Use Enter to edit fields" }
            'preview' { "Preview Mode - Read-only view" }
        }

        $hasChanges = $this.HasUnsavedChanges()
        $changeIndicator = if ($hasChanges) { " [Modified]" } else { "" }

        Write-Host "$statusColor$status$changeIndicator$resetColor" -NoNewline
    }

    [bool] HasUnsavedChanges() {
        # Compare current state with original
        $currentDescription = $this.DescriptionLines -join "`n"
        $originalDescription = $this.OriginalData.description

        return ($currentDescription -ne $originalDescription) -or
               ($this.Project -ne $this.OriginalData.project) -or
               ($this.Priority -ne $this.OriginalData.priority) -or
               ($this.DueDate -ne $this.OriginalData.due)
    }

    [void] EditorLoop() {
        while ($true) {
            $key = [Console]::ReadKey($true)

            switch ($key.Key) {
                'F1' {
                    $this.Mode = 'description'
                    $this.DrawTaskContent()
                    $this.DrawStatusLine()
                }
                'F2' {
                    $this.Mode = 'metadata'
                    $this.DrawTaskContent()
                    $this.DrawStatusLine()
                }
                'F3' {
                    $this.Mode = 'preview'
                    $this.DrawTaskContent()
                    $this.DrawStatusLine()
                }
                'Escape' {
                    if ($this.ConfirmExit()) { return }
                }
                'S' {
                    if ($key.Modifiers -band [ConsoleModifiers]::Control) {
                        $this.SaveTask()
                        return
                    }
                }
                default {
                    $this.HandleModeSpecificInput($key)
                }
            }
        }
    }

    [void] HandleModeSpecificInput([ConsoleKeyInfo]$key) {
        switch ($this.Mode) {
            'description' { $this.HandleDescriptionInput($key) }
            'metadata' { $this.HandleMetadataInput($key) }
            # Preview mode is read-only
        }

        $this.DrawTaskContent()
        $this.DrawStatusLine()
    }

    [void] HandleDescriptionInput([ConsoleKeyInfo]$key) {
        switch ($key.Key) {
            'UpArrow' {
                if ($this.CurrentLine -gt 0) {
                    $this.CurrentLine--
                    $this.CursorColumn = [Math]::Min($this.CursorColumn, $this.DescriptionLines[$this.CurrentLine].Length)
                }
            }
            'DownArrow' {
                if ($this.CurrentLine -lt ($this.DescriptionLines.Count - 1)) {
                    $this.CurrentLine++
                    $this.CursorColumn = [Math]::Min($this.CursorColumn, $this.DescriptionLines[$this.CurrentLine].Length)
                }
            }
            'LeftArrow' {
                if ($this.CursorColumn -gt 0) {
                    $this.CursorColumn--
                }
            }
            'RightArrow' {
                if ($this.CursorColumn -lt $this.DescriptionLines[$this.CurrentLine].Length) {
                    $this.CursorColumn++
                }
            }
            'Enter' {
                # Split current line at cursor position
                $currentLineText = $this.DescriptionLines[$this.CurrentLine]
                $beforeCursor = $currentLineText.Substring(0, $this.CursorColumn)
                $afterCursor = $currentLineText.Substring($this.CursorColumn)

                $this.DescriptionLines[$this.CurrentLine] = $beforeCursor
                $this.DescriptionLines = $this.DescriptionLines[0..$this.CurrentLine] + @($afterCursor) + $this.DescriptionLines[($this.CurrentLine + 1)..($this.DescriptionLines.Count - 1)]

                $this.CurrentLine++
                $this.CursorColumn = 0
            }
            'Backspace' {
                if ($this.CursorColumn -gt 0) {
                    $currentLineText = $this.DescriptionLines[$this.CurrentLine]
                    $newLine = $currentLineText.Substring(0, $this.CursorColumn - 1) + $currentLineText.Substring($this.CursorColumn)
                    $this.DescriptionLines[$this.CurrentLine] = $newLine
                    $this.CursorColumn--
                } elseif ($this.CurrentLine -gt 0) {
                    # Join with previous line
                    $prevLine = $this.DescriptionLines[$this.CurrentLine - 1]
                    $currentLineText = $this.DescriptionLines[$this.CurrentLine]
                    $this.CursorColumn = $prevLine.Length
                    $this.DescriptionLines[$this.CurrentLine - 1] = $prevLine + $currentLineText
                    $this.DescriptionLines = $this.DescriptionLines[0..($this.CurrentLine - 1)] + $this.DescriptionLines[($this.CurrentLine + 1)..($this.DescriptionLines.Count - 1)]
                    $this.CurrentLine--
                }
            }
            default {
                # Regular character input
                if ([char]::IsControl($key.KeyChar)) { return }

                $currentLineText = $this.DescriptionLines[$this.CurrentLine]
                $newLine = $currentLineText.Substring(0, $this.CursorColumn) + $key.KeyChar + $currentLineText.Substring($this.CursorColumn)
                $this.DescriptionLines[$this.CurrentLine] = $newLine
                $this.CursorColumn++
            }
        }
    }

    [void] HandleMetadataInput([ConsoleKeyInfo]$key) {
        # Metadata editing would be implemented here
        # For now, just basic navigation
    }

    [bool] ConfirmExit() {
        if (-not $this.HasUnsavedChanges()) {
            return $true
        }

        [Console]::SetCursorPosition(0, [PmcTerminalService]::GetHeight() - 1)
        Write-PmcStyled -Style 'Warning' -Text "Unsaved changes! Exit anyway? (y/N): " -NoNewline

        $response = [Console]::ReadKey($true)
        return ($response.Key -eq 'Y')
    }

    [void] SaveTask() {
        try {
            # Update task data
            $this.TaskData.description = $this.DescriptionLines -join "`n"
            $this.TaskData.project = $this.Project
            $this.TaskData.priority = $this.Priority
            $this.TaskData.due = $this.DueDate

            # Save via PMC command
            $updateCmd = "task edit $($this.TaskId) '$($this.TaskData.description)'"
            if ($this.Project) { $updateCmd += " @$($this.Project)" }
            if ($this.Priority) { $updateCmd += " $($this.Priority)" }
            if ($this.DueDate) { $updateCmd += " due:$($this.DueDate)" }

            Invoke-PmcCommand $updateCmd

            [Console]::SetCursorPosition(0, [PmcTerminalService]::GetHeight() - 1)
            Write-PmcStyled -Style 'Success' -Text "✓ Task saved successfully!"
            Start-Sleep -Seconds 1

        } catch {
            [Console]::SetCursorPosition(0, [PmcTerminalService]::GetHeight() - 1)
            Write-PmcStyled -Style 'Error' -Text ("✗ Error saving task: {0}" -f $_)
            Start-Sleep -Seconds 2
        }
    }
}

function Invoke-PmcTaskEditor {
    <#
    .SYNOPSIS
    Opens the interactive task editor for a specific task

    .PARAMETER TaskId
    The ID of the task to edit

    .EXAMPLE
    Invoke-PmcTaskEditor -TaskId "123"
    Opens the full-screen editor for task 123
    #>
    param(
        [Parameter(Mandatory)]
        [string]$TaskId
    )

    try {
        $editor = [PmcTaskEditor]::new($TaskId)
        $editor.Show()

    } catch {
        Write-PmcStyled -Style 'Error' -Text ("Error opening task editor: {0}" -f $_)
    }
}

# Export for module use
#Export-ModuleMember -Function Invoke-PmcTaskEditor


# END FILE: ./module/Pmc.Strict/src/TaskEditor.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/Tasks.ps1
# SIZE: 6.93 KB
# MODIFIED: 2025-09-23 06:00:39
# ================================================================================

# Tasks.ps1 - Core task management functions

function Add-PmcTask {
    param([PmcCommandContext]$Context)

    if (-not $Context -or $Context.FreeText.Count -eq 0) {
        Write-PmcStyled -Style 'Error' -Text "Usage: task add <description>"
        return
    }

    $taskText = ($Context.FreeText -join ' ').Trim()

    try {
        $allData = Get-PmcAllData

        # Create new task
        $newTask = @{
            id = Get-PmcNextTaskId $allData
            text = $taskText
            project = $allData.currentContext
            priority = 0
            completed = $false
            created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            status = 'pending'
            tags = @()
            depends = @()
            notes = @()
            recur = $null
            estimatedMinutes = $null
            due = $null
            nextSuggestedCount = 3
            lastNextShown = (Get-Date).ToString('yyyy-MM-dd')
        }

        # Add to tasks
        if (-not $allData.tasks) { $allData.tasks = @() }
        $allData.tasks += $newTask

        # Save data
        Set-PmcAllData $allData

        Write-PmcStyled -Style 'Success' -Text "✓ Task added: $taskText"

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error adding task: $_"
    }
}

function Get-PmcTaskListOld {
    param([PmcCommandContext]$Context)

    try {
        $allData = Get-PmcAllData
        $tasks = $allData.tasks | Where-Object { -not $_.completed }

        # Apply project filter if specified
        Write-Host "DEBUG TASK LIST: Context.Args = $($Context.Args | ConvertTo-Json -Compress)"
        Write-Host "DEBUG TASK LIST: Context.Args type = $($Context.Args.GetType().Name)"
        Write-Host "DEBUG TASK LIST: ContainsKey check = $($Context.Args.ContainsKey('project'))"

        if ($Context.Args -and $Context.Args.ContainsKey('project')) {
            $projectFilter = $Context.Args['project']
            Write-Host "DEBUG: Filtering tasks by project '$projectFilter'"
            $originalCount = $tasks.Count
            $tasks = $tasks | Where-Object { $_.project -eq $projectFilter }
            Write-Host "DEBUG: Filtered from $originalCount to $($tasks.Count) tasks"
        } else {
            Write-Host "DEBUG: No project filter applied"
        }

        if (-not $tasks) {
            $filterMsg = if ($Context.Args -and $Context.Args.ContainsKey('project')) { " for project '$($Context.Args['project'])'" } else { "" }
            Write-PmcStyled -Style 'Info' -Text "No active tasks found$filterMsg"
            return
        }

        # Use universal display
        $title = if ($Context.Args -and $Context.Args.ContainsKey('project')) { "Active Tasks — @$($Context.Args['project'])" } else { "Active Tasks" }
        Show-PmcCustomGrid -Domain 'task' -Data $tasks -Title $title

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error listing tasks: $_"
    }
}

function Complete-PmcTask {
    param([PmcCommandContext]$Context)

    if (-not $Context -or $Context.FreeText.Count -eq 0) {
        Write-PmcStyled -Style 'Error' -Text "Usage: task done <id>"
        return
    }

    $taskId = $Context.FreeText[0]

    try {
        $allData = Get-PmcAllData
        $task = $allData.tasks | Where-Object { $_.id -eq $taskId }

        if (-not $task) {
            Write-PmcStyled -Style 'Error' -Text "Task '$taskId' not found"
            return
        }

        $task.completed = $true
        $task.status = 'completed'

        Set-PmcAllData $allData
        Write-PmcStyled -Style 'Success' -Text "✓ Task completed: $($task.text)"

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error completing task: $_"
    }
}

function Remove-PmcTask {
    param([PmcCommandContext]$Context)

    if (-not $Context -or $Context.FreeText.Count -eq 0) {
        Write-PmcStyled -Style 'Error' -Text "Usage: task delete <id>"
        return
    }

    $taskId = $Context.FreeText[0]

    try {
        $allData = Get-PmcAllData
        $task = $allData.tasks | Where-Object { $_.id -eq $taskId }

        if (-not $task) {
            Write-PmcStyled -Style 'Error' -Text "Task '$taskId' not found"
            return
        }

        # Move to deleted
        if (-not $allData.deleted) { $allData.deleted = @() }
        $allData.deleted += $task

        # Remove from tasks
        $allData.tasks = $allData.tasks | Where-Object { $_.id -ne $taskId }

        Set-PmcAllData $allData
        Write-PmcStyled -Style 'Success' -Text "✓ Task deleted: $($task.text)"

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error deleting task: $_"
    }
}

function Show-PmcTask {
    param([PmcCommandContext]$Context)

    if (-not $Context -or $Context.FreeText.Count -eq 0) {
        Write-PmcStyled -Style 'Error' -Text "Usage: task view <id>"
        return
    }

    $taskId = $Context.FreeText[0]

    try {
        $allData = Get-PmcAllData
        $task = $allData.tasks | Where-Object { $_.id -eq $taskId }

        if (-not $task) {
            Write-PmcStyled -Style 'Error' -Text "Task '$taskId' not found"
            return
        }

        Write-PmcStyled -Style 'Header' -Text "`nTask: $($task.text)"
        Write-PmcStyled -Style 'Body' -Text "ID: $($task.id)"
        Write-PmcStyled -Style 'Body' -Text "Project: $($task.project)"
        Write-PmcStyled -Style 'Body' -Text "Priority: $($task.priority)"
        Write-PmcStyled -Style 'Body' -Text "Status: $($task.status)"
        Write-PmcStyled -Style 'Body' -Text "Created: $($task.created)"
        if ($task.due) { Write-PmcStyled -Style 'Body' -Text "Due: $($task.due)" }

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error viewing task: $_"
    }
}

function Set-PmcTask {
    param([PmcCommandContext]$Context)

    if (-not $Context -or $Context.FreeText.Count -lt 3) {
        Write-PmcStyled -Style 'Error' -Text "Usage: task update <id> <field> <value>"
        return
    }

    $taskId = $Context.FreeText[0]
    $field = $Context.FreeText[1]
    $value = ($Context.FreeText[2..($Context.FreeText.Count-1)] -join ' ')

    try {
        $allData = Get-PmcAllData
        $task = $allData.tasks | Where-Object { $_.id -eq $taskId }

        if (-not $task) {
            Write-PmcStyled -Style 'Error' -Text "Task '$taskId' not found"
            return
        }

        switch ($field.ToLower()) {
            'text' { $task.text = $value }
            'priority' { $task.priority = [int]$value }
            'project' { $task.project = $value }
            'due' { $task.due = $value }
            default {
                Write-PmcStyled -Style 'Error' -Text "Unknown field '$field'. Available: text, priority, project, due"
                return
            }
        }

        Set-PmcAllData $allData
        Write-PmcStyled -Style 'Success' -Text "✓ Task updated"

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error updating task: $_"
    }
}

# Export all task functions
Export-ModuleMember -Function Add-PmcTask, Complete-PmcTask, Remove-PmcTask, Show-PmcTask, Set-PmcTask

# END FILE: ./module/Pmc.Strict/src/Tasks.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/TerminalDimensions.ps1
# SIZE: 5.89 KB
# MODIFIED: 2025-09-22 17:43:07
# ================================================================================

# TerminalDimensions.ps1 - Centralized terminal dimension service for PMC
# Provides consistent screen dimension handling across all components

Set-StrictMode -Version Latest

class PmcTerminalService {
    static [int] $CachedWidth = 0
    static [int] $CachedHeight = 0
    static [datetime] $LastUpdate = [datetime]::MinValue
    static [int] $CacheValidityMs = 500  # Cache dimensions for 500ms

    static [hashtable] GetDimensions() {
        $now = [datetime]::Now
        if (($now - [PmcTerminalService]::LastUpdate).TotalMilliseconds -lt [PmcTerminalService]::CacheValidityMs -and
            [PmcTerminalService]::CachedWidth -gt 0 -and [PmcTerminalService]::CachedHeight -gt 0) {
            return @{
                Width = [PmcTerminalService]::CachedWidth
                Height = [PmcTerminalService]::CachedHeight
                MinWidth = 40
                MinHeight = 10
                IsCached = $true
            }
        }

        # Refresh cache
        try {
            [PmcTerminalService]::CachedWidth = [Console]::WindowWidth
            [PmcTerminalService]::CachedHeight = [Console]::WindowHeight
            [PmcTerminalService]::LastUpdate = $now
        } catch {
            # Fallback values if console access fails
            [PmcTerminalService]::CachedWidth = 80
            [PmcTerminalService]::CachedHeight = 24
        }

        # Apply minimum constraints
        if ([PmcTerminalService]::CachedWidth -lt 40) { [PmcTerminalService]::CachedWidth = 80 }
        if ([PmcTerminalService]::CachedHeight -lt 10) { [PmcTerminalService]::CachedHeight = 24 }

        return @{
            Width = [PmcTerminalService]::CachedWidth
            Height = [PmcTerminalService]::CachedHeight
            MinWidth = 40
            MinHeight = 10
            IsCached = $false
        }
    }

    static [int] GetWidth() {
        return [PmcTerminalService]::GetDimensions().Width
    }

    static [int] GetHeight() {
        return [PmcTerminalService]::GetDimensions().Height
    }

    static [void] InvalidateCache() {
        [PmcTerminalService]::LastUpdate = [datetime]::MinValue
    }

    static [bool] ValidateContent([string]$Content, [int]$MaxWidth = 0, [int]$MaxHeight = 0) {
        $dims = [PmcTerminalService]::GetDimensions()
        $actualMaxWidth = if ($MaxWidth -gt 0) { [Math]::Min($MaxWidth, $dims.Width) } else { $dims.Width }
        $actualMaxHeight = if ($MaxHeight -gt 0) { [Math]::Min($MaxHeight, $dims.Height) } else { $dims.Height }

        $lines = $Content -split "`n"
        if (@($lines).Count -gt $actualMaxHeight) { return $false }

        foreach ($line in $lines) {
            # Strip ANSI codes for accurate width measurement
            $cleanLine = $line -replace '\e\[[0-9;]*m', ''
            if ($cleanLine.Length -gt $actualMaxWidth) { return $false }
        }

        return $true
    }

    static [string] EnforceContentBounds([string]$Content, [int]$MaxWidth = 0, [int]$MaxHeight = 0) {
        $dims = [PmcTerminalService]::GetDimensions()
        $actualMaxWidth = if ($MaxWidth -gt 0) { [Math]::Min($MaxWidth, $dims.Width) } else { $dims.Width }
        $actualMaxHeight = if ($MaxHeight -gt 0) { [Math]::Min($MaxHeight, $dims.Height) } else { $dims.Height }

        $lines = $Content -split "`n"
        $resultLines = @()

        # Truncate height if needed
        $linesToProcess = if (@($lines).Count -gt $actualMaxHeight) {
            $lines[0..($actualMaxHeight - 1)]
        } else {
            $lines
        }

        # Truncate width for each line
        foreach ($line in $linesToProcess) {
            if ($line.Length -le $actualMaxWidth) {
                $resultLines += $line
            } else {
                # Check if line contains ANSI codes
                if ($line -match '\e\[[0-9;]*m') {
                    # Complex truncation preserving ANSI codes
                    $resultLines += [PmcTerminalService]::TruncateWithAnsi($line, $actualMaxWidth)
                } else {
                    # Simple truncation
                    $resultLines += $line.Substring(0, [Math]::Min($line.Length, $actualMaxWidth - 3)) + "..."
                }
            }
        }

        return ($resultLines -join "`n")
    }

    static [string] TruncateWithAnsi([string]$Text, [int]$MaxWidth) {
        # Preserve ANSI codes while truncating visible text
        $ansiPattern = '\e\[[0-9;]*m'
        $parts = $Text -split "($ansiPattern)"
        $result = ""
        $visibleLength = 0

        foreach ($part in $parts) {
            if ($part -match $ansiPattern) {
                # ANSI code - add without counting length
                $result += $part
            } else {
                # Regular text - check length
                $remainingSpace = $MaxWidth - $visibleLength
                if ($remainingSpace -le 0) { break }

                if ($part.Length -le $remainingSpace) {
                    $result += $part
                    $visibleLength += $part.Length
                } else {
                    $result += $part.Substring(0, [Math]::Max(0, $remainingSpace - 3)) + "..."
                    break
                }
            }
        }

        return $result
    }
}

# Convenience functions for backward compatibility
function Get-PmcTerminalWidth { return [PmcTerminalService]::GetWidth() }
function Get-PmcTerminalHeight { return [PmcTerminalService]::GetHeight() }
function Get-PmcTerminalDimensions { return [PmcTerminalService]::GetDimensions() }
function Test-PmcContentBounds { param([string]$Content, [int]$MaxWidth = 0, [int]$MaxHeight = 0) return [PmcTerminalService]::ValidateContent($Content, $MaxWidth, $MaxHeight) }
function Set-PmcContentBounds { param([string]$Content, [int]$MaxWidth = 0, [int]$MaxHeight = 0) return [PmcTerminalService]::EnforceContentBounds($Content, $MaxWidth, $MaxHeight) }

#Export-ModuleMember -Function Get-PmcTerminalWidth, Get-PmcTerminalHeight, Get-PmcTerminalDimensions, Test-PmcContentBounds, Set-PmcContentBounds

# END FILE: ./module/Pmc.Strict/src/TerminalDimensions.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/Theme.ps1
# SIZE: 11.07 KB
# MODIFIED: 2025-09-24 05:33:24
# ================================================================================

# Theme and Preferences management

function Initialize-PmcThemeSystem {
    # Force VT/ANSI capabilities; no fallbacks
    $caps = @{ AnsiSupport=$true; TrueColorSupport=$true; IsTTY=$true; NoColor=$false; Platform='forced' }
    Set-PmcState -Section 'Display' -Key 'Capabilities' -Value $caps

    # Normalize theme from config
    $cfg = Get-PmcConfig
    $theme = @{ PaletteName='default'; Hex='#33aaff'; TrueColor=$true; HighContrast=$false; ColorBlindMode='none' }
    try {
        if ($cfg.Display -and $cfg.Display.Theme) {
            if ($cfg.Display.Theme.Hex) { $theme.Hex = ($cfg.Display.Theme.Hex.ToString()) }
            if ($cfg.Display.Theme.Enabled -ne $null) { } # reserved for future toggles
        }
        if ($cfg.Display -and $cfg.Display.Icons -and $cfg.Display.Icons.Mode) {
            Set-PmcState -Section 'Display' -Key 'Icons' -Value @{ Mode = ($cfg.Display.Icons.Mode.ToString()) }
        }
    } catch { }
    Set-PmcState -Section 'Display' -Key 'Theme' -Value $theme

    # Compute simple style tokens (expand later)
    $styles = @{
        Title    = @{ Fg='Cyan'   }
        Header   = @{ Fg='Yellow' }
        Body     = @{ Fg='White'  }
        Muted    = @{ Fg='Gray'   }
        Success  = @{ Fg='Green'  }
        Warning  = @{ Fg='Yellow' }
        Error    = @{ Fg='Red'    }
        Info     = @{ Fg='Cyan'   }
        Prompt   = @{ Fg='DarkGray' }
        Border   = @{ Fg='DarkCyan' }
        Highlight= @{ Fg='Magenta' }
        Editing  = @{ Bg='BrightBlue'; Fg='White'; Bold=$true }
        Selected = @{ Bg='#0078d4'; Fg='White' }
    }
    Set-PmcState -Section 'Display' -Key 'Styles' -Value $styles
}

function Set-PmcTheme {
    param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category "Theme" -Message "Starting theme set" -Data @{ FreeText = $Context.FreeText }
    $cfg = Get-PmcConfig
    $color = ($Context.FreeText -join ' ').Trim()
    if ([string]::IsNullOrWhiteSpace($color)) {
        Write-PmcStyled -Style 'Warning' -Text "Usage: theme <#RRGGBB> | <preset>"
        Write-PmcStyled -Style 'Muted' -Text "Presets: ocean, lime, purple, slate"
        return
    }
    $hex = $null
    switch -Regex ($color.ToLower()) {
        '^#?[0-9a-f]{6}$' { $hex = if ($color.StartsWith('#')) { $color } else { '#'+$color } ; break }
        '^ocean$'   { $hex = '#33aaff'; break }
        '^lime$'    { $hex = '#33cc66'; break }
        '^purple$'  { $hex = '#9966ff'; break }
        '^slate$'   { $hex = '#8899aa'; break }
        default     { }
    }
    if (-not $hex) { Write-PmcStyled -Style 'Error' -Text "Invalid color. Use #RRGGBB or a preset."; return }
    try {
        if (-not $cfg.Display) { $cfg.Display = @{} }
        if (-not $cfg.Display.Theme) { $cfg.Display.Theme = @{} }
        $cfg.Display.Theme.Hex = $hex
        $cfg.Display.Theme.Enabled = $true
        Save-PmcConfig $cfg
        Write-PmcStyled -Style 'Success' -Text ("Theme color set to {0}" -f $hex)
    } catch {
        Write-PmcStyled -Style 'Error' -Text "Failed to save theme"
    }
}

function Reset-PmcTheme {
    param($Context = $null)
    try {
        $cfg = Get-PmcConfig
        if (-not $cfg) { $cfg = @{} }
        if (-not (Pmc-HasProp $cfg 'Display')) { $cfg | Add-Member -NotePropertyName 'Display' -NotePropertyValue @{} -Force }
        if (-not (Pmc-HasProp $cfg.Display 'Theme')) { $cfg.Display | Add-Member -NotePropertyName 'Theme' -NotePropertyValue @{} -Force }
        $cfg.Display.Theme.Hex = '#33aaff'
        $cfg.Display.Theme.Enabled = $true
        Save-PmcConfig $cfg
        Write-PmcStyled -Style 'Success' -Text "Theme reset to default (#33aaff)"
    } catch {
        Write-PmcStyled -Style 'Warning' -Text "Theme reset completed (config may be read-only)"
    }
}

function Set-PmcIconMode {
    param([PmcCommandContext]$Context)
    $mode = ($Context.FreeText -join ' ').Trim().ToLower()
    if ([string]::IsNullOrWhiteSpace($mode)) {
        Write-PmcStyled -Style 'Warning' -Text "Usage: config icons ascii|emoji"
        return
    }
    if ($mode -notin @('ascii','emoji')) { Write-PmcStyled -Style 'Error' -Text "Invalid mode. Use ascii or emoji."; return }
    $cfg = Get-PmcConfig
    if (-not $cfg.Display) { $cfg.Display = @{} }
    if (-not $cfg.Display.Icons) { $cfg.Display.Icons = @{} }
    $cfg.Display.Icons.Mode = $mode
    Save-PmcConfig $cfg
    Write-PmcStyled -Style 'Success' -Text ("Icon mode set to {0}" -f $mode)
}

function Edit-PmcTheme {
    param([PmcCommandContext]$Context)

    # Read current theme
    $cfg = Get-PmcConfig
    $hex = try { if ($cfg.Display -and $cfg.Display.Theme -and $cfg.Display.Theme.Hex) { [string]$cfg.Display.Theme.Hex } else { '#33aaff' } } catch { '#33aaff' }
    if (-not $hex.StartsWith('#')) { $hex = '#'+$hex }
    $rgb = ConvertFrom-PmcHex $hex
    $r = [int]$rgb.R; $g=[int]$rgb.G; $b=[int]$rgb.B
    $chan = 0  # 0=R,1=G,2=B

    $done = $false
    while (-not $done) {
        # Render UI
        Write-Host ([PraxisVT]::ClearScreen())
        Show-PmcHeader -Title 'THEME ADJUSTER' -Icon '🎨'
        Write-Host ''

        # Preview box
        $preview = [PmcVT]::BgRGB($r,$g,$b) + '          ' + [PmcVT]::Reset() + ("  #{0:X2}{1:X2}{2:X2}" -f $r,$g,$b)
        Write-Host ("  Preview: " + $preview)
        Write-Host ''

        # Sliders
        Show-Slider -Label 'R' -Value $r -Selected:($chan -eq 0)
        Show-Slider -Label 'G' -Value $g -Selected:($chan -eq 1)
        Show-Slider -Label 'B' -Value $b -Selected:($chan -eq 2)

        Write-Host ''
        Write-Host '  Use ↑/↓ to select channel, ←/→ to adjust, PgUp/PgDn for ±10, Enter to save, Esc to cancel' -ForegroundColor DarkGray

        # Read key
        $k = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        switch ($k.VirtualKeyCode) {
            38 { $chan = [Math]::Max(0, $chan - 1) }       # Up
            40 { $chan = [Math]::Min(2, $chan + 1) }       # Down
            37 { if ($chan -eq 0) { $r = [Math]::Max(0,$r-1) } elseif ($chan -eq 1) { $g=[Math]::Max(0,$g-1) } else { $b=[Math]::Max(0,$b-1) } }  # Left
            39 { if ($chan -eq 0) { $r = [Math]::Min(255,$r+1) } elseif ($chan -eq 1) { $g=[Math]::Min(255,$g+1) } else { $b=[Math]::Min(255,$b+1) } } # Right
            33 { if ($chan -eq 0) { $r = [Math]::Min(255,$r+10) } elseif ($chan -eq 1) { $g=[Math]::Min(255,$g+10) } else { $b=[Math]::Min(255,$b+10) } } # PgUp
            34 { if ($chan -eq 0) { $r = [Math]::Max(0,$r-10) } elseif ($chan -eq 1) { $g=[Math]::Max(0,$g-10) } else { $b=[Math]::Max(0,$b-10) } } # PgDn
            13 {
                # Enter: save and exit
                $newHex = ("#{0:X2}{1:X2}{2:X2}" -f $r,$g,$b)
                if (-not $cfg.Display) { $cfg.Display=@{} }
                if (-not $cfg.Display.Theme) { $cfg.Display.Theme=@{} }
                $cfg.Display.Theme.Hex = $newHex
                Save-PmcConfig $cfg
                Write-Host "Saved theme: $newHex" -ForegroundColor Green
                Start-Sleep -Milliseconds 400
                $done = $true
            }
            27 { $done = $true } # Esc: cancel
            default {}
        }
    }
}

function Show-Slider {
    param(
        [string]$Label,
        [int]$Value,
        [switch]$Selected
    )
    $width = 32
    $filled = [int]([Math]::Round(($Value / 255.0) * $width))
    $bar = ('#' * $filled) + ('-' * ($width - $filled))
    $sel = if ($Selected) { '▶' } else { ' ' }
    $fg = if ($Selected) { 'White' } else { 'Gray' }
    Write-Host ("  {0} {1}: [{2}] {3,3}" -f $sel, $Label, $bar, $Value) -ForegroundColor $fg
}

function Show-PmcPreferences {
    param([PmcCommandContext]$Context)
    $cfg = Get-PmcConfig
    Write-Host "\nPREFERENCES" -ForegroundColor Cyan
    Write-PmcStyled -Style 'Border' -Text "───────────"
    Write-Host ("1) Theme color: {0}" -f ($cfg.Display.Theme.Hex ?? '#33aaff'))
    Write-Host ("2) Icons: {0}" -f ($cfg.Display.Icons.Mode ?? 'emoji'))
    Write-Host ("3) CSV ledger: {0}" -f ($cfg.Behavior.EnableCsvLedger ?? $true))
    Write-Host "q) Quit"
    while ($true) {
        $sel = Read-Host "Select option (1/2/3/q)"
        switch ($sel) {
            '1' {
                # Launch interactive adjuster with preview and sliders
                $ctx = [PmcCommandContext]::new('theme','adjust')
                Edit-PmcTheme -Context $ctx
            }
            '2' {
                $m = Read-Host "Enter icons mode (ascii/emoji)"
                $ctx = [PmcCommandContext]::new('config','icons'); $ctx.FreeText = @($m)
                Set-PmcIconMode -Context $ctx
            }
            '3' {
                $v = Read-Host "Enable CSV ledger? (y/n)"
                $flag = ($v -match '^(?i)y')
                if (-not $cfg.Behavior) { $cfg.Behavior=@{} }
                $cfg.Behavior.EnableCsvLedger = $flag
                Save-PmcConfig $cfg
                Write-Host ("CSV ledger set to {0}" -f $flag) -ForegroundColor Green
            }
            'q' { break }
            default { Write-Host 'Invalid choice' -ForegroundColor Yellow }
        }
    }
}

# Additional theme utilities and commands
function Get-PmcThemeList { [PmcCommandContext]$Context | Out-Null; @('default','ocean','#33aaff','lime','#33cc66','purple','#9966ff','slate','#8899aa','high-contrast') | ForEach-Object { Write-Host $_ } }

function Apply-PmcTheme {
    param([PmcCommandContext]$Context)
    $arg = ($Context.FreeText -join ' ').Trim()
    if (-not $arg) { Write-Host "Usage: theme apply <name|#RRGGBB>" -ForegroundColor Yellow; return }
    $hex = $null
    switch -Regex ($arg.ToLower()) {
        '^#?[0-9a-f]{6}$' { $hex = if ($arg.StartsWith('#')) { $arg } else { '#'+$arg } ; break }
        '^(default|ocean)$' { $hex = '#33aaff'; break }
        '^lime$'    { $hex = '#33cc66'; break }
        '^purple$'  { $hex = '#9966ff'; break }
        '^slate$'   { $hex = '#8899aa'; break }
        '^high-contrast$' { $hex = '#00ffff'; break }
        default {}
    }
    if (-not $hex) { Write-Host "Unknown theme; see 'theme list'" -ForegroundColor Yellow; return }
    $cfg = Get-PmcConfig
    if (-not $cfg.Display) { $cfg.Display=@{} }
    if (-not $cfg.Display.Theme) { $cfg.Display.Theme=@{} }
    $cfg.Display.Theme.Hex = $hex
    Save-PmcConfig $cfg
    Initialize-PmcThemeSystem
    Write-Host ("Theme applied: {0}" -f $hex) -ForegroundColor Green
}

function Show-PmcThemeInfo { param([PmcCommandContext]$Context)
    $disp = Get-PmcState -Section 'Display'
    $theme = $disp.Theme
    Write-Host "Theme: $($theme.PaletteName) $($theme.Hex)  TrueColor=$($theme.TrueColor) HighContrast=$($theme.HighContrast)" -ForegroundColor Cyan
}

function Reload-PmcConfig { param([PmcCommandContext]$Context)
    # Re-apply runtime from config (providers already return latest on read)
    $cfg = Get-PmcConfig
    $lvl = try { [int]$cfg.Debug.Level } catch { 0 }
    Initialize-PmcDebugSystem -Level $lvl
    Initialize-PmcSecuritySystem
    Initialize-PmcThemeSystem
    Ensure-PmcUniversalDisplay
    Write-Host "Configuration reloaded and systems re-initialized" -ForegroundColor Green
}

Export-ModuleMember -Function Initialize-PmcThemeSystem, Set-PmcTheme, Reset-PmcTheme, Set-PmcIconMode, Edit-PmcTheme, Show-Slider, Show-PmcPreferences, Get-PmcThemeList, Apply-PmcTheme, Show-PmcThemeInfo


# END FILE: ./module/Pmc.Strict/src/Theme.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/Time.ps1
# SIZE: 13.25 KB
# MODIFIED: 2025-09-23 20:29:23
# ================================================================================

# Time.ps1 - Time tracking and timer functions

function Add-PmcTimeEntry {
    param($Context)

    try {
        $allData = Get-PmcAllData

        # Default values for new time entry
        $entry = @{
            id = Get-PmcNextTimeId $allData
            project = $allData.currentContext
            id1 = $null
            id2 = $null
            date = (Get-Date).ToString('yyyy-MM-dd')
            minutes = 0
            description = ""
            created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        }

        # Parse free text for time entry details
        if ($Context.FreeText.Count -gt 0) {
            $text = ($Context.FreeText -join ' ').Trim()

            # Parse minutes from text (look for numbers followed by 'm' or 'min')
            if ($text -match '(\d+)m(?:in)?') {
                $entry.minutes = [int]$matches[1]
                $text = $text -replace '\d+m(?:in)?', ''
            }

            # Parse indirect code from #code syntax (2-5 digits)
            if ($text -match '#(\d{2,5})') {
                $entry.id1 = $matches[1]
                $entry.project = $null  # Indirect means no project
                $text = $text -replace '#\d{2,5}', ''
            }
            # Parse project from @project syntax (only if no indirect code)
            elseif ($text -match '@(\w+)') {
                $entry.project = $matches[1]
                $text = $text -replace '@\w+', ''
            }

            # Parse date from text (YYYYMMDD or MMDD format)
            if ($text -match '\b(?:(\d{4})(\d{2})(\d{2})|(\d{2})(\d{2}))\b') {
                if ($matches[1]) {
                    # YYYYMMDD format
                    $year = [int]$matches[1]
                    $month = [int]$matches[2]
                    $day = [int]$matches[3]
                } else {
                    # MMDD format - assume current year
                    $year = (Get-Date).Year
                    $month = [int]$matches[4]
                    $day = [int]$matches[5]
                }
                try {
                    $entry.date = (Get-Date -Year $year -Month $month -Day $day).ToString('yyyy-MM-dd')
                    $text = $text -replace '\b(?:\d{4}\d{2}\d{2}|\d{2}\d{2})\b', ''
                } catch {
                    # Invalid date, keep default
                }
            }

            # Rest is description
            $entry.description = $text.Trim()
        }

        # Add to time entries
        if (-not $allData.timelogs) { $allData.timelogs = @() }
        $allData.timelogs += $entry

        Set-PmcAllData $allData
        $target = if ($entry.id1) { "#$($entry.id1)" } else { "@$($entry.project)" }
        Write-PmcStyled -Style 'Success' -Text "✓ Time entry added: $($entry.minutes)m $target - $($entry.description)"

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error adding time entry: $_"
    }
}

function Get-PmcTimeReport {
    param($Context)

    try {
        $allData = Get-PmcAllData
        $timelogs = $allData.timelogs | Where-Object { $_ }

        if (-not $timelogs) {
            Write-PmcStyled -Style 'Info' -Text "No time entries found"
            return
        }

        # Determine week to display (current week default)
        $weekOffset = 0
        if ($Context.Args.ContainsKey('week')) {
            try { $weekOffset = [int]$Context.Args['week'] } catch {}
        }

        Show-PmcWeeklyTimeReport -TimeLogs $timelogs -WeekOffset $weekOffset

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error generating time report: $_"
    }
}

function Show-PmcWeeklyTimeReport {
    param([array]$TimeLogs, [int]$WeekOffset = 0)

    # Calculate week start (Monday)
    $today = Get-Date
    $daysFromMonday = ($today.DayOfWeek.value__ + 6) % 7  # Monday = 0
    $thisMonday = $today.AddDays(-$daysFromMonday).Date
    $weekStart = $thisMonday.AddDays($WeekOffset * 7)
    $weekEnd = $weekStart.AddDays(4)  # Friday

    # Week header
    $weekHeader = "Week of {0} - {1}" -f $weekStart.ToString('MMM dd'), $weekEnd.ToString('MMM dd, yyyy')
    Write-PmcStyled -Style 'Header' -Text "`n📊 TIME REPORT"
    Write-PmcStyled -Style 'Subheader' -Text $weekHeader
    Write-PmcStyled -Style 'Info' -Text "Use '=' next week, '-' previous week`n"

    # Filter logs for the week
    $weekLogs = @()
    for ($d = 0; $d -lt 5; $d++) {
        $dayDate = $weekStart.AddDays($d).ToString('yyyy-MM-dd')
        $dayLogs = $TimeLogs | Where-Object { $_.date -eq $dayDate }
        $weekLogs += $dayLogs
    }

    if ($weekLogs.Count -eq 0) {
        Write-PmcStyled -Style 'Warning' -Text "No time entries for this week"
        return
    }

    # Group by project/indirect code
    $grouped = @{}
    foreach ($log in $weekLogs) {
        $key = if ($log.id1) {
            "#$($log.id1)"
        } else {
            $log.project ?? 'Unknown'
        }

        if (-not $grouped.ContainsKey($key)) {
            $grouped[$key] = @{
                Name = if ($log.id1) { "" } else { $log.project ?? 'Unknown' }
                ID1 = if ($log.id1) { $log.id1 } else { '' }
                ID2 = if ($log.id1) { '' } else { '' }
                Mon = 0; Tue = 0; Wed = 0; Thu = 0; Fri = 0; Total = 0
            }
        }

        # Add minutes to appropriate day
        $logDate = [datetime]$log.date
        $dayIndex = ($logDate.DayOfWeek.value__ + 6) % 7  # Monday = 0
        $hours = [Math]::Round($log.minutes / 60.0, 1)

        switch ($dayIndex) {
            0 { $grouped[$key].Mon += $hours }
            1 { $grouped[$key].Tue += $hours }
            2 { $grouped[$key].Wed += $hours }
            3 { $grouped[$key].Thu += $hours }
            4 { $grouped[$key].Fri += $hours }
        }
        $grouped[$key].Total += $hours
    }

    # Display table
    $headerFormat = "{0,-20} {1,-5} {2,-5} {3,6} {4,6} {5,6} {6,6} {7,6} {8,8}"
    $rowFormat = "{0,-20} {1,-5} {2,-5} {3,6:F1} {4,6:F1} {5,6:F1} {6,6:F1} {7,6:F1} {8,8:F1}"

    Write-Host ($headerFormat -f "Name", "ID1", "ID2", "Mon", "Tue", "Wed", "Thu", "Fri", "Total") -ForegroundColor Cyan
    Write-Host ("─" * 80) -ForegroundColor DarkGray

    $grandTotal = 0
    foreach ($entry in ($grouped.GetEnumerator() | Sort-Object Key)) {
        $data = $entry.Value
        Write-Host ($rowFormat -f $data.Name, $data.ID1, $data.ID2, $data.Mon, $data.Tue, $data.Wed, $data.Thu, $data.Fri, $data.Total)
        $grandTotal += $data.Total
    }

    Write-Host ("─" * 80) -ForegroundColor DarkGray
    Write-Host ($headerFormat -f "", "", "", "", "", "", "", "Total:", $grandTotal.ToString('F1')) -ForegroundColor Yellow

    # Interactive week navigation
    Write-PmcStyled -Style 'Info' -Text "`nPress '=' for next week, '-' for previous week, any other key to exit"

    while ($true) {
        $key = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        if ($key.Character -eq '=') {
            Show-PmcWeeklyTimeReport -TimeLogs $TimeLogs -WeekOffset ($WeekOffset + 1)
            break
        } elseif ($key.Character -eq '-') {
            Show-PmcWeeklyTimeReport -TimeLogs $TimeLogs -WeekOffset ($WeekOffset - 1)
            break
        } else {
            break
        }
    }
}

function Get-PmcTimeList {
    param($Context)

    try {
        $allData = Get-PmcAllData
        $timelogs = $allData.timelogs | Where-Object { $_ }

        if (-not $timelogs) {
            Write-PmcStyled -Style 'Info' -Text "No time entries found"
            return
        }

        # Filter recent entries (last 30 days)
        $recent = $timelogs | Where-Object {
            [datetime]$_.date -ge (Get-Date).AddDays(-30)
        } | Sort-Object date -Descending

        # Use template display
        $timeTemplate = [PmcTemplate]::new('time-list', @{
            type = 'grid'
            header = 'ID     Date       Project/Code  Hours   Description'
            row = '{id,-6} {date,-10} {target,-12} {hours,6:F1} {description}'
            settings = @{ separator = '─'; minWidth = 60 }
        })

        # Format data for display
        $displayData = @()
        foreach ($log in $recent) {
            $target = if ($log.id1) { "#$($log.id1)" } else { $log.project ?? 'Unknown' }
            $hours = [Math]::Round($log.minutes / 60.0, 1)
            $displayData += [pscustomobject]@{
                id = $log.id
                date = $log.date
                target = $target
                hours = $hours
                description = $log.description ?? ''
            }
        }

        Write-PmcStyled -Style 'Header' -Text "`n⏰ RECENT TIME ENTRIES`n"
        Render-GridTemplate -Data $displayData -Template $timeTemplate

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error listing time entries: $_"
    }
}

function Edit-PmcTimeEntry {
    param($Context)

    if (-not $Context -or $Context.FreeText.Count -eq 0) {
        Write-PmcStyled -Style 'Error' -Text "Usage: time edit <id>"
        return
    }

    $entryId = $Context.FreeText[0]

    try {
        $allData = Get-PmcAllData
        $entry = $allData.timelogs | Where-Object { $_.id -eq $entryId }

        if (-not $entry) {
            Write-PmcStyled -Style 'Error' -Text "Time entry '$entryId' not found"
            return
        }

        Write-PmcStyled -Style 'Info' -Text "Time entry editing not yet implemented"

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error editing time entry: $_"
    }
}

function Remove-PmcTimeEntry {
    param($Context)

    if (-not $Context -or $Context.FreeText.Count -eq 0) {
        Write-PmcStyled -Style 'Error' -Text "Usage: time delete <id>"
        return
    }

    $entryId = $Context.FreeText[0]

    try {
        $allData = Get-PmcAllData
        $entry = $allData.timelogs | Where-Object { $_.id -eq $entryId }

        if (-not $entry) {
            Write-PmcStyled -Style 'Error' -Text "Time entry '$entryId' not found"
            return
        }

        # Remove from time logs
        $allData.timelogs = $allData.timelogs | Where-Object { $_.id -ne $entryId }

        Set-PmcAllData $allData
        Write-PmcStyled -Style 'Success' -Text "✓ Time entry deleted"

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error deleting time entry: $_"
    }
}

function Start-PmcTimer {
    param($Context)

    try {
        $project = if ($Context.FreeText.Count -gt 0) {
            $Context.FreeText[0]
        } else {
            $allData = Get-PmcAllData
            $allData.currentContext
        }

        Set-PmcState -Section 'Timer' -Key 'Running' -Value $true
        Set-PmcState -Section 'Timer' -Key 'Project' -Value $project
        Set-PmcState -Section 'Timer' -Key 'StartTime' -Value (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')

        Write-PmcStyled -Style 'Success' -Text "⏱️ Timer started for project: $project"

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error starting timer: $_"
    }
}

function Stop-PmcTimer {
    param($Context)

    try {
        $running = Get-PmcState -Section 'Timer' -Key 'Running'
        if (-not $running) {
            Write-PmcStyled -Style 'Warning' -Text "No timer is currently running"
            return
        }

        $project = Get-PmcState -Section 'Timer' -Key 'Project'
        $startTime = [datetime](Get-PmcState -Section 'Timer' -Key 'StartTime')
        $endTime = Get-Date
        $minutes = [Math]::Round(($endTime - $startTime).TotalMinutes, 0)

        # Create time entry
        $allData = Get-PmcAllData
        $entry = @{
            id = Get-PmcNextTimeId $allData
            project = $project
            date = $startTime.ToString('yyyy-MM-dd')
            minutes = $minutes
            description = "Timer session"
            created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        }

        if (-not $allData.timelogs) { $allData.timelogs = @() }
        $allData.timelogs += $entry
        Set-PmcAllData $allData

        # Clear timer state
        Set-PmcState -Section 'Timer' -Key 'Running' -Value $false

        Write-PmcStyled -Style 'Success' -Text "⏹️ Timer stopped. Logged $minutes minutes to $project"

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error stopping timer: $_"
    }
}

function Get-PmcTimerStatus {
    param($Context)

    try {
        $running = Get-PmcState -Section 'Timer' -Key 'Running'

        if (-not $running) {
            Write-PmcStyled -Style 'Info' -Text "⏱️ No timer is currently running"
            return
        }

        $project = Get-PmcState -Section 'Timer' -Key 'Project'
        $startTime = [datetime](Get-PmcState -Section 'Timer' -Key 'StartTime')
        $elapsed = (Get-Date) - $startTime
        $minutes = [Math]::Round($elapsed.TotalMinutes, 0)

        Write-PmcStyled -Style 'Warning' -Text "⏱️ Timer running for $project ($minutes minutes elapsed)"

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error checking timer status: $_"
    }
}

function Get-PmcNextTimeId {
    param($data)

    if (-not $data.timelogs -or $data.timelogs.Count -eq 0) {
        return "T001"
    }

    $maxId = 0
    foreach ($entry in $data.timelogs) {
        if ($entry.id -match '^T(\d+)$') {
            $num = [int]$matches[1]
            if ($num -gt $maxId) { $maxId = $num }
        }
    }

    return "T{0:000}" -f ($maxId + 1)
}

Export-ModuleMember -Function Add-PmcTimeEntry, Get-PmcTimeReport, Get-PmcTimeList, Edit-PmcTimeEntry, Remove-PmcTimeEntry, Start-PmcTimer, Stop-PmcTimer, Get-PmcTimerStatus, Show-PmcWeeklyTimeReport

# END FILE: ./module/Pmc.Strict/src/Time.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/Types.ps1
# SIZE: 3.84 KB
# MODIFIED: 2025-09-24 05:28:47
# ================================================================================

# Types and context for the strict engine

Set-StrictMode -Version Latest

class PmcCommandContext {
    [string] $Domain
    [string] $Action
    [hashtable] $Args = @{}
    [string[]] $FreeText = @()
    [string] $Raw = ''

    PmcCommandContext([string]$domain, [string]$action) {
        $this.Domain = $domain
        $this.Action = $action
    }
}

function ConvertTo-PmcTokens {
    param([string]$Buffer)

    # Always return an array, even for empty input
    if ([string]::IsNullOrWhiteSpace($Buffer)) {
        return ,[string[]]@()
    }

    # Simple split preserving quoted strings
    $pattern = '"([^"]*)"|(\S+)'
    $tokens = [string[]]@()

    foreach ($m in [regex]::Matches($Buffer, $pattern)) {
        if ($m.Groups[1].Success) {
            $tokens += $m.Groups[1].Value
        } elseif ($m.Groups[2].Success) {
            $tokens += $m.Groups[2].Value
        }
    }

    # Ensure we always return an array type with Count property
    return ,[string[]]$tokens
}

# Property helpers (consistent across PSCustomObject/Hashtable)
function Pmc-HasProp {
    param($Object, [string]$Name)
    if ($null -eq $Object -or [string]::IsNullOrWhiteSpace($Name)) { return $false }
    try {
        if ($Object -is [hashtable]) { return $Object.ContainsKey($Name) }
        $psobj = $Object.PSObject
        if ($null -eq $psobj) { return $false }
        return ($psobj.Properties[$Name] -ne $null)
    } catch { return $false }
}

function Pmc-GetProp {
    param($Object, [string]$Name, $Default=$null)
    if (-not (Pmc-HasProp $Object $Name)) { return $Default }
    try { return $Object.$Name } catch { return $Default }
}

function Ensure-PmcTaskProperties {
    <#
    .SYNOPSIS
    Ensures all required properties exist on a task object with proper defaults

    .DESCRIPTION
    Normalizes task objects by adding missing properties with appropriate default values.
    This prevents "property cannot be found" errors when accessing task properties.

    .PARAMETER Task
    The task object to normalize
    #>
    param($Task)

    if ($null -eq $Task) { return }

    # Required task properties with their default values
    $requiredProperties = @{
        'depends' = @()
        'tags' = @()
        'notes' = @()
        'recur' = $null
        'estimatedMinutes' = $null
        'nextSuggestedCount' = 3
        'lastNextShown' = (Get-Date).ToString('yyyy-MM-dd')
        'status' = 'pending'
        'priority' = 0
        'created' = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        'project' = 'inbox'
        'due' = $null
    }

    foreach ($propName in $requiredProperties.Keys) {
        if (-not (Pmc-HasProp $Task $propName)) {
            try {
                Add-Member -InputObject $Task -MemberType NoteProperty -Name $propName -NotePropertyValue $requiredProperties[$propName] -Force
            } catch {
                # Ignore errors - property may already exist or object may be read-only
            }
        }
    }
}

function Ensure-PmcProjectProperties {
    <#
    .SYNOPSIS
    Ensures all required properties exist on a project object
    #>
    param($Project)

    if ($null -eq $Project) { return }

    $requiredProperties = @{
        'name' = ''
        'description' = ''
        'aliases' = @()
        'created' = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        'isArchived' = $false
        'color' = 'Gray'
        'icon' = '📁'
        'sortOrder' = 0
    }

    foreach ($propName in $requiredProperties.Keys) {
        if (-not (Pmc-HasProp $Project $propName)) {
            try {
                Add-Member -InputObject $Project -MemberType NoteProperty -Name $propName -NotePropertyValue $requiredProperties[$propName] -Force
            } catch {
                # Ignore errors
            }
        }
    }
}

Export-ModuleMember -Function ConvertTo-PmcTokens, Pmc-HasProp, Pmc-GetProp, Ensure-PmcTaskProperties, Ensure-PmcProjectProperties


# END FILE: ./module/Pmc.Strict/src/Types.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/UI.ps1
# SIZE: 6.8 KB
# MODIFIED: 2025-09-24 05:25:12
# ================================================================================

# Pmc UI primitives with centralized style tokens and sanitization

Set-StrictMode -Version Latest

class PmcVT {
    static [string] MoveTo([int]$x, [int]$y) { return "`e[$($y + 1);$($x + 1)H" }
    static [string] Clear() { return "`e[2J`e[H" }
    static [string] ClearLine() { return "`e[2K" }
    static [string] Hide() { return "`e[?25l" }
    static [string] Show() { return "`e[?25h" }
    static [string] FgRGB([int]$r, [int]$g, [int]$b) { return "`e[38;2;$r;$g;${b}m" }
    static [string] BgRGB([int]$r, [int]$g, [int]$b) { return "`e[48;2;$r;$g;${b}m" }
    static [string] Reset() { return "`e[0m" }
    static [string] Bold() { return "`e[1m" }
}

function Sanitize-PmcOutput {
    param([string]$Text)
    if (-not $Text) { return '' }
    # Strip ANSI escape sequences and control chars
    $t = $Text -replace "`e\[[0-9;]*[A-Za-z]", ''
    $t = ($t.ToCharArray() | Where-Object { [int]$_ -ge 32 -or [int]$_ -eq 10 -or [int]$_ -eq 13 } ) -join ''
    return $t
}

function Get-PmcStyle {
    param([string]$Token)
    $styles = Get-PmcState -Section 'Display' -Key 'Styles'
    if (-not $styles) { return @{ Fg='White' } }
    if ($styles.ContainsKey($Token)) { return $styles[$Token] }
    return @{ Fg='White' }
}

function Write-PmcStyled {
    param(
        [Parameter(Mandatory)] [string]$Style,
        [Parameter(Mandatory)] [string]$Text,
        [switch]$NoNewline
    )
    $sty = Get-PmcStyle $Style
    $fg = $sty.Fg
    $safe = Sanitize-PmcOutput $Text
    if ($fg) {
        if ($NoNewline) { Write-Host -NoNewline $safe -ForegroundColor $fg } else { Write-Host $safe -ForegroundColor $fg }
    } else {
        if ($NoNewline) { Write-Host -NoNewline $safe } else { Write-Host $safe }
    }
}

function ConvertFrom-PmcHex {
    param([string]$Hex)
    $h = if ($Hex) { $Hex.Trim() } else { '#33aaff' }
    if ($h.StartsWith('#')) { $h = $h.Substring(1) }
    if ($h.Length -eq 3) { $h = ($h[0]+$h[0]+$h[1]+$h[1]+$h[2]+$h[2]) }
    if ($h.Length -ne 6) { $h = '33aaff' }
    return @{
        R = [Convert]::ToInt32($h.Substring(0,2),16)
        G = [Convert]::ToInt32($h.Substring(2,2),16)
        B = [Convert]::ToInt32($h.Substring(4,2),16)
    }
}

function Get-PmcColorPalette {
    $cfg = Get-PmcConfig
    $hex = '#33aaff'
    try { if ($cfg.Display -and $cfg.Display.Theme -and $cfg.Display.Theme.Hex) { $hex = [string]$cfg.Display.Theme.Hex } } catch {
        # Theme configuration access failed - use default hex color
    }
    $rgb = ConvertFrom-PmcHex $hex
    # Simple derived shades
    $dim = @{
        R = [int]([Math]::Max(0, $rgb.R * 0.7)); G = [int]([Math]::Max(0, $rgb.G * 0.7)); B = [int]([Math]::Max(0, $rgb.B * 0.7))
    }
    $text = @{ R=220; G=220; B=220 }
    $muted = @{ R=150; G=150; B=150 }
    $warning = @{ R=220; G=180; B=80 }
    $error = @{ R=220; G=80; B=80 }
    $success = @{ R=80; G=200; B=120 }

    # Provide all tokens used by interactive UIs (wizard/editor)
    return @{
        Primary  = $rgb
        Border   = $dim
        Text     = $text
        Muted    = $muted
        Error    = $error
        Warning  = $warning
        Success  = $success
        # Additional expected tokens
        Header   = $rgb
        Label    = $muted
        Highlight= $rgb
        Footer   = $dim
        Cursor   = $rgb
        Status   = $muted
    }
}

function Get-PmcColorSequence {
    param($rgb)
    try {
        if ($rgb -and $rgb.PSObject -and $rgb.PSObject.Properties['R'] -and $rgb.PSObject.Properties['G'] -and $rgb.PSObject.Properties['B']) {
            return ([PmcVT]::FgRGB([int]$rgb.R, [int]$rgb.G, [int]$rgb.B))
        }
    } catch { }
    return ''
}

# Cell-level theming hook for grid renderer (Stage 1.3)
function Get-PmcCellStyle {
    param([object]$RowData, [string]$Column, [object]$Value)

    if (-not $RowData) { return Get-PmcStyle 'Body' }

    # Priority-based coloring (1=highest)
    if ($Column -eq 'priority' -and $RowData.PSObject.Properties['priority'] -and $RowData.priority) {
        $p = [string]$RowData.priority
        switch ($p) {
            '1' { return @{ Fg = 'Red';    Bold = $true } }
            '2' { return @{ Fg = 'Yellow'; Bold = $true } }
            '3' { return @{ Fg = 'Green' } }
        }
    }

    # Due date warnings (expects yyyy-MM-dd)
    if ($Column -eq 'due' -and $RowData.PSObject.Properties['due'] -and $RowData.due) {
        $dstr = [string]$RowData.due
        try {
            $dt = [DateTime]::ParseExact($dstr, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
            $ok = $true
        } catch {
            $ok = $false
        }
        if ($ok) {
            $today = (Get-Date).Date
            if ($dt.Date -lt $today) { return @{ Fg = 'Red'; Bold = $true } }
            if ($dt.Date -le $today.AddDays(1)) { return @{ Fg = 'Yellow'; Bold = $true } }
        }
    }

    return Get-PmcStyle 'Body'
}

function Show-PmcHeader {
    param([string]$Title,[string]$Icon='')
    $t = if ($Icon) { " $Icon $Title" } else { " $Title" }
    Write-PmcStyled -Style 'Title' -Text $t
    $width = [Math]::Max(8, $t.Length)
    Write-PmcStyled -Style 'Border' -Text ('-' * $width)
}

function Show-PmcTip { param([string]$Text) Write-PmcStyled -Style 'Muted' -Text ('  ' + $Text) }

function Get-PmcIcon {
    param([string]$Name)
    $mode = 'emoji'
    try { $cfg = Get-PmcConfig; if ($cfg.Display -and $cfg.Display.Icons -and $cfg.Display.Icons.Mode) { $mode = [string]$cfg.Display.Icons.Mode } } catch {
        # Icon configuration access failed - use default mode
    }
    switch ($Name) {
        'notice' { return ($mode -eq 'ascii') ? '*' : '•' }
        'warn'   { return ($mode -eq 'ascii') ? '!' : '⚠' }
        'error'  { return ($mode -eq 'ascii') ? 'X' : '✖' }
        'ok'     { return ($mode -eq 'ascii') ? '+' : '✓' }
        default  { return '' }
    }
}

function Show-PmcNotice { param([string]$Text) $i=(Get-PmcIcon 'notice'); Write-PmcStyled -Style 'Body' -Text ($i + ' ' + $Text) }
function Show-PmcWarning { param([string]$Text) $i=(Get-PmcIcon 'warn'); Write-PmcStyled -Style 'Warning' -Text ($i + ' ' + $Text) }
function Show-PmcError { param([string]$Text) $i=(Get-PmcIcon 'error'); Write-PmcStyled -Style 'Error' -Text ($i + ' ' + $Text) }
function Show-PmcSuccess { param([string]$Text) $i=(Get-PmcIcon 'ok'); Write-PmcStyled -Style 'Success' -Text ($i + ' ' + $Text) }
function Show-PmcSeparator { param([int]$Width=40) Write-PmcStyled -Style 'Border' -Text ('─' * [Math]::Max(8,$Width)) }

function Show-PmcTable {
    param(
        [array]$Columns,
        [array]$Rows,
        [string]$Title=''
    )
    throw "Show-PmcTable is DEPRECATED and should not be used! All views must use Show-PmcCustomGrid. Function called with Title: '$Title'"
}

Export-ModuleMember -Function Sanitize-PmcOutput, Get-PmcStyle, Write-PmcStyled, ConvertFrom-PmcHex, Get-PmcColorPalette, Get-PmcColorSequence, Get-PmcCellStyle, Show-PmcHeader, Show-PmcTip, Get-PmcIcon


# END FILE: ./module/Pmc.Strict/src/UI.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/UndoRedo.ps1
# SIZE: 9.14 KB
# MODIFIED: 2025-09-24 05:31:34
# ================================================================================

# Undo/Redo System Implementation
# Based on t2.ps1 undo/redo functionality

# Global variables for undo/redo stacks
$Script:PmcUndoStack = @()
$Script:PmcRedoStack = @()
$Script:PmcMaxUndoSteps = 5

function Invoke-PmcUndo {
    param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category "System" -Message "Starting undo operation"
    $file = Get-PmcTaskFilePath
    $stacks = Get-PmcUndoRedoStacks $file
    $undo = @($stacks.undo); $redo = @($stacks.redo)
    if (@($undo).Count -eq 0) { Write-PmcStyled -Style 'Muted' -Text 'Nothing to undo'; return }
    try {
        $current = Get-PmcData
        $redo += ($current | ConvertTo-Json -Depth 10)
    } catch {
        # Undo state push failed - undo history may be incomplete
    }
    $snap = $undo[-1]; if (@($undo).Count -gt 1) { $undo = $undo[0..($undo.Count-2)] } else { $undo=@() }
    try {
        $state = $snap | ConvertFrom-Json
        $tmp = "$file.tmp"; $state | ConvertTo-Json -Depth 10 | Set-Content -Path $tmp -Encoding UTF8; Move-Item -Force -Path $tmp -Destination $file
        Save-PmcUndoRedoStacks -Undo $undo -Redo $redo -UndoFile $stacks.undoFile -RedoFile $stacks.redoFile
        Write-PmcStyled -Style 'Success' -Text 'Undid last action'
        Write-PmcDebug -Level 2 -Category 'System' -Message 'Undo completed' -Data @{ UndoCount=@($undo).Count; RedoCount=@($redo).Count }
    } catch {
        Write-PmcStyled -Style 'Error' -Text ("Undo failed: {0}" -f $_)
    }
}

function Invoke-PmcRedo {
    param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category "System" -Message "Starting redo operation"
    $file = Get-PmcTaskFilePath
    $stacks = Get-PmcUndoRedoStacks $file
    $undo = @($stacks.undo); $redo = @($stacks.redo)
    if (@($redo).Count -eq 0) { Write-PmcStyled -Style 'Muted' -Text 'Nothing to redo'; return }
    $snap = $redo[-1]; if (@($redo).Count -gt 1) { $redo = $redo[0..($redo.Count-2)] } else { $redo=@() }
    try {
        $current = Get-PmcData
        $undo += ($current | ConvertTo-Json -Depth 10)
    } catch {
        # Undo state push failed - undo history may be incomplete
    }
    try {
        $state = $snap | ConvertFrom-Json
        $tmp = "$file.tmp"; $state | ConvertTo-Json -Depth 10 | Set-Content -Path $tmp -Encoding UTF8; Move-Item -Force -Path $tmp -Destination $file
        Save-PmcUndoRedoStacks -Undo $undo -Redo $redo -UndoFile $stacks.undoFile -RedoFile $stacks.redoFile
        Write-PmcStyled -Style 'Success' -Text 'Redid last action'
        Write-PmcDebug -Level 2 -Category 'System' -Message 'Redo completed' -Data @{ UndoCount=@($undo).Count; RedoCount=@($redo).Count }
    } catch {
        Write-PmcStyled -Style 'Error' -Text ("Redo failed: {0}" -f $_)
    }
}

function New-PmcBackup {
    param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category "System" -Message "Starting manual backup"

    try {
        $data = Get-PmcDataAlias
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

        # Create backups directory if it doesn't exist
        $backupDir = "backups"
        if (-not (Test-Path $backupDir)) {
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }

        $backupFile = Join-Path $backupDir "pmc_backup_$timestamp.json"

        # Export data to backup file
        $data | ConvertTo-Json -Depth 10 | Set-Content -Path $backupFile -Encoding UTF8

        Write-PmcStyled -Style 'Success' -Text ("Backup created: {0}" -f $backupFile)

        # Clean up old backups (keep last 2)
        $backupFiles = Get-ChildItem -Path $backupDir -Filter "pmc_backup_*.json" | Sort-Object LastWriteTime -Descending
        if ($backupFiles.Count -gt 2) {
            $oldBackups = $backupFiles | Select-Object -Skip 2
            foreach ($oldBackup in $oldBackups) {
                Remove-Item $oldBackup.FullName -Force
                Write-PmcStyled -Style 'Muted' -Text ("Removed old backup: {0}" -f $oldBackup.Name)
            }
        }

        Write-PmcDebug -Level 2 -Category "System" -Message "Manual backup completed successfully" -Data @{ BackupFile = $backupFile }
    } catch {
        Write-PmcStyled -Style 'Error' -Text ("Backup failed: {0}" -f $_)
        Write-PmcDebug -Level 1 -Category "System" -Message "Manual backup failed" -Data @{ Error = $_.Exception.Message }
    }
}

function Clear-PmcBackups {
    param([PmcCommandContext]$Context)
    Write-PmcDebug -Level 1 -Category "System" -Message "Starting system clean"

    $data = Get-PmcDataAlias
    $completedTasks = @($data.tasks | Where-Object { $_.status -eq 'completed' })

    if ($completedTasks.Count -eq 0) {
        Write-PmcStyled -Style 'Muted' -Text "No completed tasks to clean"
        return
    }

    Write-PmcStyled -Style 'Warning' -Text ("Found {0} completed tasks" -f $completedTasks.Count)

    # Show sample of what will be cleaned
    $sample = $completedTasks | Select-Object -First 5
    foreach ($task in $sample) {
        $completedDate = if ($task.completed) { $task.completed } else { 'unknown' }
        Write-PmcStyled -Style 'Muted' -Text ("  #$($task.id) - $($task.text) (completed: $completedDate)")
    }

    if ($completedTasks.Count -gt 5) {
        Write-PmcStyled -Style 'Muted' -Text ("  ... and {0} more" -f ($completedTasks.Count - 5))
    }

    # Ask for confirmation
    $response = Read-Host "`nProceed with cleaning? This will permanently remove completed tasks. (y/N)"

    if ($response -match '^[Yy]') {
        # Record current state for undo
        Record-PmcUndoState $data 'system clean'

        # Remove completed tasks
        $data.tasks = @($data.tasks | Where-Object { $_.status -ne 'completed' })

        # Save cleaned data
        Save-StrictData $data 'system clean'

        Write-PmcStyled -Style 'Success' -Text ("Cleaned {0} completed tasks" -f $completedTasks.Count)

        Write-PmcDebug -Level 2 -Category "System" -Message "System clean completed successfully" -Data @{ RemovedTasks = $completedTasks.Count }
    } else {
        Write-PmcStyled -Style 'Muted' -Text "Clean operation cancelled"
    }
}

# Initialize undo system - integrate with existing Add-PmcUndoEntry mechanism
function Initialize-PmcUndoSystem {
    $taskFile = Get-PmcTaskFilePath
    $undoFile = $taskFile + '.undo'

    if (-not $Script:PmcUndoStack -or $Script:PmcUndoStack.Count -eq 0) {
        if (Test-Path $undoFile) {
            try {
                $undoStack = Get-Content $undoFile -Raw | ConvertFrom-Json
                $Script:PmcUndoStack = @($undoStack)

                Write-PmcDebug -Level 3 -Category "System" -Message "Undo system initialized from existing file" -Data @{
                    UndoSteps = $Script:PmcUndoStack.Count
                    RedoSteps = $Script:PmcRedoStack.Count
                }
            } catch {
                $Script:PmcUndoStack = @()
                $Script:PmcRedoStack = @()
                Write-PmcDebug -Level 1 -Category "System" -Message "Failed to load undo data" -Data @{ Error = $_.Exception.Message }
            }
        } else {
            $Script:PmcUndoStack = @()
            $Script:PmcRedoStack = @()
        }
    }
}

# Record state for undo
function Record-PmcUndoState {
    param($data, [string]$action)

    if (-not $data) { return }

    # Add current state to undo stack
    $Script:PmcUndoStack += ($data | ConvertTo-Json -Depth 10)

    # Limit undo stack size
    if ($Script:PmcUndoStack.Count -gt $Script:PmcMaxUndoSteps) {
        $Script:PmcUndoStack = $Script:PmcUndoStack[1..($Script:PmcUndoStack.Count-1)]
    }

    # Clear redo stack when new action is performed
    $Script:PmcRedoStack = @()

    # Save undo stack
    Save-PmcUndoStack

    Write-PmcDebug -Level 3 -Category "System" -Message "Undo state recorded" -Data @{
        Action = $action
        UndoStackSize = $Script:PmcUndoStack.Count
    }
}

# Save undo stack to disk
function Save-PmcUndoStack {
    $undoFile = "pmc_undo.json"

    try {
        $undoData = @{
            undoStack = $Script:PmcUndoStack
            redoStack = $Script:PmcRedoStack
            lastUpdated = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        }

        $undoData | ConvertTo-Json -Depth 10 | Set-Content -Path $undoFile -Encoding UTF8

        Write-PmcDebug -Level 3 -Category "System" -Message "Undo stack saved to disk"
    } catch {
        Write-PmcDebug -Level 1 -Category "System" -Message "Failed to save undo stack" -Data @{ Error = $_.Exception.Message }
    }
}

# Save data directly without recording undo state
function Save-PmcDataDirect {
    param($data)

    $dataFile = "pmc_data.json"
    $data | ConvertTo-Json -Depth 10 | Set-Content -Path $dataFile -Encoding UTF8

    # Update in-memory cache if it exists
    if (Get-Variable -Name 'Script:PmcDataCache' -Scope Script -ErrorAction SilentlyContinue) {
        $Script:PmcDataCache = $data
    }
}

# Get undo/redo status
function Get-PmcUndoStatus {
    Initialize-PmcUndoSystem

    return @{
        UndoSteps = $Script:PmcUndoStack.Count
        RedoSteps = $Script:PmcRedoStack.Count
        MaxSteps = $Script:PmcMaxUndoSteps
    }
}

Export-ModuleMember -Function Invoke-PmcUndo, Invoke-PmcRedo, New-PmcBackup, Clear-PmcBackups, Initialize-PmcUndoSystem, Record-PmcUndoState, Save-PmcUndoStack, Save-PmcDataDirect, Get-PmcUndoStatus


# END FILE: ./module/Pmc.Strict/src/UndoRedo.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/UniversalDisplay.ps1
# SIZE: 15.39 KB
# MODIFIED: 2025-09-24 05:24:00
# ================================================================================

# Universal Display System - Command routing for unified grid interface
# Replaces all fragmented Show-Pmc* functions with grid-based equivalents

Set-StrictMode -Version Latest

# Main universal data display dispatcher
function Show-PmcData {
    param(
        [string]$DataType,              # "tasks", "projects", "timelog", "stats"
        [hashtable]$Filters = @{},      # Data filters
        [hashtable]$Columns = @{},      # Column configuration
        [string]$Title = "",            # Display title
        [hashtable]$Theme = @{},        # Theme overrides
        [switch]$Interactive,           # Start interactive mode (overridden by -i flag in Context)
        [PmcCommandContext]$Context = $null  # PMC command context
    )

    Write-PmcDebug -Level 2 -Category "UniversalDisplay" -Message "Universal data display" -Data @{
        DataType = $DataType
        Interactive = $Interactive.IsPresent
        FilterCount = $Filters.Keys.Count
    }

    # Default column configurations for different data types
    if ($Columns.Keys.Count -eq 0) {
        $Columns = Get-PmcDefaultColumns -DataType $DataType
    }

    # Add help navigation callback if this is help data
    $additionalParams = @{}
    if ($DataType -eq "help" -and $Interactive) {
        $additionalParams.OnSelectCallback = {
            param($selectedItem)
            Show-PmcHelpCategory -Category $selectedItem.Category -Context $Context
        }
    }

    # Call the enhanced grid system
    Write-PmcDebug -Level 2 -Category 'UniversalDisplay' -Message 'Show-PmcData calling Show-PmcDataGrid' -Data @{ DataType = $DataType; Interactive = $Interactive.IsPresent }
    # Determine interactive based on explicit param or Context -i flag
    $startInteractive = $Interactive.IsPresent
    try { if (-not $startInteractive -and $Context -and $Context.Args.ContainsKey('interactive') -and $Context.Args['interactive']) { $startInteractive = $true } } catch {}

    Show-PmcDataGrid -Domains @($DataType) -Columns $Columns -Filters $Filters -Title $Title -Theme $Theme -Interactive:$startInteractive @additionalParams
}

function Get-PmcDefaultColumns {
    param([string]$DataType)

    switch ($DataType) {
        "task" {
            return @{
                "id" = @{ Header = "#"; Width = 4; Alignment = "Right"; Editable = $false; Sensitive = $true }
                "text" = @{ Header = "Task"; Width = 40; Alignment = "Left"; Editable = $true }
                "project" = @{ Header = "Project"; Width = 12; Alignment = "Left"; Truncate = $true; Editable = $false; Sensitive = $true }
                "due" = @{ Header = "Due"; Width = 8; Alignment = "Center"; Editable = $true }
                "priority" = @{ Header = "P"; Width = 3; Alignment = "Center"; Editable = $true }
            }
        }
        "help" {
            return @{
                "Category" = @{ Header = "Category"; Width = 25; Alignment = "Left"; Editable = $false }
                "CommandCount" = @{ Header = "Commands"; Width = 10; Alignment = "Right"; Editable = $false }
                "Description" = @{ Header = "Description"; Width = 50; Alignment = "Left"; Editable = $false }
            }
        }
        "project" {
            return @{
                "name" = @{ Header = "Project"; Width = 20; Alignment = "Left" }
                "description" = @{ Header = "Description"; Width = 30; Alignment = "Left"; Truncate = $true }
                "task_count" = @{ Header = "Tasks"; Width = 6; Alignment = "Right" }
                "completion" = @{ Header = "%"; Width = 6; Alignment = "Right" }
            }
        }
        "timelog" {
            return @{
                "date" = @{ Header = "Date"; Width = 10; Alignment = "Center" }
                "project" = @{ Header = "Project"; Width = 15; Alignment = "Left" }
                "duration" = @{ Header = "Duration"; Width = 8; Alignment = "Right" }
                "description" = @{ Header = "Description"; Width = 35; Alignment = "Left"; Truncate = $true }
            }
        }
        default {
            return @{
                "id" = @{ Header = "#"; Width = 6; Alignment = "Right" }
                "name" = @{ Header = "Item"; Width = 30; Alignment = "Left" }
                "value" = @{ Header = "Value"; Width = 20; Alignment = "Left" }
            }
        }
    }
}

# Enhanced task view functions using universal system
function Show-PmcTodayTasksInteractive {
    param([PmcCommandContext]$Context)

    $today = (Get-Date).Date
    $title = "📅 TASKS DUE TODAY - {0}" -f $today.ToString('yyyy-MM-dd')

    Show-PmcData -DataType "task" -Filters @{
        "status" = "pending"
        "due_range" = "today"
    } -Title $title -Interactive -Context $Context
}

function Show-PmcOverdueTasksInteractive {
    param([PmcCommandContext]$Context)

    Show-PmcData -DataType "task" -Filters @{
        "status" = "pending"
        "due_range" = "overdue"
    } -Title "⚠️  OVERDUE TASKS" -Interactive -Context $Context
}

function Show-PmcAgendaInteractive {
    param([PmcCommandContext]$Context)

    $today = (Get-Date).Date
    $title = "🗓️ AGENDA - {0}" -f $today.ToString('yyyy-MM-dd')

    Show-PmcData -DataType "task" -Filters @{
        "status" = "pending"
        "due_range" = "overdue_and_today"
    } -Title $title -Interactive -Context $Context
}

function Show-PmcProjectsInteractive {
    param([PmcCommandContext]$Context)

    Show-PmcData -DataType "project" -Filters @{
        "archived" = $false
    } -Title "📊 PROJECTS DASHBOARD" -Interactive -Context $Context
}

# Static list of projects (no screen takeover)
function Get-PmcProjectList {
    param([PmcCommandContext]$Context)
    $filters = @{ archived = $false }

    # Use simple template-based display
    if (Get-Command Show-PmcSimpleData -ErrorAction SilentlyContinue) {
        Show-PmcSimpleData -DataType "project" -Filters $filters
    } else {
        # Fallback to old system
        Show-PmcData -DataType "project" -Filters $filters -Title "Projects" -Context $Context
    }
}

function Show-PmcAllTasksInteractive {
    param([PmcCommandContext]$Context)

    Show-PmcData -DataType "task" -Filters @{
        "status" = "pending"
    } -Title "📋 ALL TASKS" -Interactive -Context $Context
}

# Static list of tasks (pending by default; honors @project when provided)
function Get-PmcTaskList {
    param($Context)

    $filters = @{ status = 'pending' }
    try {
        if ($Context -and $Context.Args -and $Context.Args.ContainsKey('project')) {
            $filters['project'] = [string]$Context.Args['project']
        }
        if ($Context -and $Context.Args -and $Context.Args.ContainsKey('due')) {
            $dv = ([string]$Context.Args['due']).ToLower()
            switch ($dv) {
                'today'   { $filters['due_range'] = 'today' }
                'overdue' { $filters['due_range'] = 'overdue' }
                'upcoming'{ $filters['due_range'] = 'upcoming' }
            }
        }
    } catch {}

    # Use simple template-based display instead of complex TUI
    if (Get-Command Show-PmcSimpleData -ErrorAction SilentlyContinue) {
        Show-PmcSimpleData -DataType "task" -Filters $filters
    } else {
        # Fallback to old system if template system not loaded
        $title = "Tasks"
        if ($filters.ContainsKey('project')) { $title = "Tasks — @" + $filters['project'] }
        Show-PmcData -DataType "task" -Filters $filters -Title $title -Context $Context
    }
}

function Show-PmcTomorrowTasksInteractive {
    param([PmcCommandContext]$Context)

    $tomorrow = (Get-Date).Date.AddDays(1)
    $title = "📅 TASKS DUE TOMORROW - {0}" -f $tomorrow.ToString('yyyy-MM-dd')

    Show-PmcData -DataType "task" -Filters @{
        "status" = "pending"
        "due_range" = "tomorrow"
    } -Title $title -Interactive -Context $Context
}

function Show-PmcUpcomingTasksInteractive {
    param([PmcCommandContext]$Context)

    Show-PmcData -DataType "task" -Filters @{
        "status" = "pending"
        "due_range" = "upcoming"
    } -Title "📆 UPCOMING TASKS (7 days)" -Interactive -Context $Context
}

function Show-PmcBlockedTasksInteractive {
    param([PmcCommandContext]$Context)

    Show-PmcData -DataType "task" -Filters @{
        "status" = "pending"
        "has_dependencies" = $true
    } -Title "🚫 BLOCKED TASKS" -Interactive -Context $Context
}

function Show-PmcTasksWithoutDueDateInteractive {
    param([PmcCommandContext]$Context)

    Show-PmcData -DataType "task" -Filters @{
        "status" = "pending"
        "no_due_date" = $true
    } -Title "📋 TASKS WITHOUT DUE DATE" -Interactive -Context $Context
}

function Show-PmcNextTasksInteractive {
    param([PmcCommandContext]$Context)

    Show-PmcData -DataType "task" -Filters @{
        "status" = "pending"
        "next_actions" = $true
    } -Title "⏭️ NEXT ACTIONS" -Interactive -Context $Context
}

function Show-PmcWeekTasksInteractive {
    param([PmcCommandContext]$Context)

    Show-PmcData -DataType "task" -Filters @{
        "status" = "pending"
        "due_range" = "week"
    } -Title "📅 THIS WEEK'S TASKS" -Interactive -Context $Context
}

function Show-PmcMonthTasksInteractive {
    param([PmcCommandContext]$Context)

    Show-PmcData -DataType "task" -Filters @{
        "status" = "pending"
        "due_range" = "month"
    } -Title "📅 THIS MONTH'S TASKS" -Interactive -Context $Context
}

# Command shortcuts that route to unified display system
function Get-PmcUniversalCommands {
    return @{
        # Interactive shortcuts (using function names for PMC compatibility)
        "tasks"     = 'Show-PmcAllTasksInteractive'
        "today"     = 'Show-PmcTodayTasksInteractive'
        "overdue"   = 'Show-PmcOverdueTasksInteractive'
        "agenda"    = 'Show-PmcAgendaInteractive'
        "projects"  = 'Show-PmcProjectsInteractive'

        # Enhanced static views (preserve existing functionality)
        "tomorrow"  = 'Show-PmcTomorrowTasks'
        "upcoming"  = 'Show-PmcUpcomingTasks'
        "blocked"   = 'Show-PmcBlockedTasks'
        "noduedate" = 'Show-PmcTasksWithoutDueDate'
        "next"      = 'Show-PmcNextTasks'
        "week"      = 'Show-PmcWeekTasks'
        "month"     = 'Show-PmcMonthTasks'

        # Interactive mode aliases
        "itasks"    = 'Show-PmcAllTasksInteractive'
        "itoday"    = 'Show-PmcTodayTasksInteractive'
        "ioverdue"  = 'Show-PmcOverdueTasksInteractive'
        "iagenda"   = 'Show-PmcAgendaInteractive'
        "iprojects" = 'Show-PmcProjectsInteractive'
    }
}

# Integration with PMC's command system
function Register-PmcUniversalCommands {
    $commands = Get-PmcUniversalCommands

    # Register each command with PMC's shortcut system
    foreach ($cmdName in $commands.Keys) {
        try {
            # Override existing shortcuts in PMC's shortcut map
            if ($Script:PmcShortcutMap.ContainsKey($cmdName)) {
                Write-PmcDebug -Level 1 -Category "UniversalDisplay" -Message "Overriding existing shortcut" -Data @{ Command = $cmdName }
            }

            # Update the global shortcut map to use our interactive functions
            $Script:PmcShortcutMap[$cmdName] = $commands[$cmdName]

            Write-PmcDebug -Level 3 -Category "UniversalDisplay" -Message "Registered universal command" -Data @{ Command = $cmdName }
        } catch {
            Write-PmcDebug -Level 1 -Category "UniversalDisplay" -Message "Failed to register command" -Data @{
                Command = $cmdName
                Error = $_.Exception.Message
            }
        }
    }
}

# Enhanced view functions that preserve existing behavior but add interactive options
function Show-PmcDataWithMode {
    param(
        [string]$ViewName,
        [hashtable]$ViewConfig,
        [PmcCommandContext]$Context,
        [switch]$Interactive
    )

    if ($Interactive) {
        Show-PmcData @ViewConfig -Interactive -Context $Context
    } else {
        # Call original function if it exists
        $originalCommand = "Show-Pmc$ViewName"
        if (Get-Command $originalCommand -ErrorAction SilentlyContinue) {
            & $originalCommand $Context
        } else {
            Show-PmcData @ViewConfig -Context $Context
        }
    }
}

# Theme enhancements for better visual feedback
function Get-PmcUniversalTheme {
    param([string]$ViewType)

    $baseTheme = @{
        Default = @{ Style = "Body" }
        Columns = @{}
        Rows = @{
            Header = @{ Style = "Header" }
            Separator = @{ Style = "Border" }
        }
        Cells = @()
    }

    switch ($ViewType) {
        "today" {
            $baseTheme.Cells += @{
                Column = "due"
                Condition = { param($item) $item.due -eq (Get-Date).ToString('yyyy-MM-dd') }
                Style = @{ Fg = "Yellow"; Bold = $true }
            }
        }
        "overdue" {
            $baseTheme.Cells += @{
                Column = "due"
                Condition = { param($item)
                    if (-not $item.due) { return $false }
                    try {
                        $dueDate = [DateTime]$item.due
                        return $dueDate -lt (Get-Date).Date
                    } catch { return $false }
                }
                Style = @{ Fg = "Red"; Bold = $true }
            }
        }
        "projects" {
            $baseTheme.Cells += @{
                Column = "completion"
                Condition = { param($item)
                    if (-not $item.completion) { return $false }
                    $pct = [int]($item.completion -replace '%', '')
                    return $pct -ge 80
                }
                Style = @{ Fg = "Green"; Bold = $true }
            }
        }
    }

    return $baseTheme
}

# Help category drill-down function
function Show-PmcHelpCategory {
    param(
        [string]$Category,
        [PmcCommandContext]$Context
    )

    Write-PmcDebug -Level 1 -Category 'Help' -Message "Showing help category" -Data @{ Category = $Category }

    # Get help content for this category
    if (-not $Script:PmcHelpContent.ContainsKey($Category)) {
        Write-Host "⚠️  Category '$Category' not found in help content" -ForegroundColor Yellow
        return
    }

    $categoryData = $Script:PmcHelpContent[$Category]
    $helpItems = @()
    $id = 1

    # Convert help items to display format
    foreach ($item in $categoryData.Items) {
        $helpItems += [PSCustomObject]@{
            id = $id++
            Type = $item.Type
            Command = $item.Command
            Description = $item.Description
        }
    }

    # Use universal display system for detailed help
    $columns = @{
        "Type" = @{ Header = "Type"; Width = 12; Alignment = "Left"; Editable = $false }
        "Command" = @{ Header = "Command"; Width = 35; Alignment = "Left"; Editable = $false }
        "Description" = @{ Header = "Description"; Width = 50; Alignment = "Left"; Editable = $false }
    }

    $title = "📚 {0} - {1}" -f $Category, $categoryData.Description

    # Display with interactive mode for further navigation
    Show-PmcDataGrid -Data $helpItems -Columns $columns -Title $title -Interactive
}

Export-ModuleMember -Function Get-PmcTaskList, Get-PmcProjectList, Show-PmcData, Show-PmcTodayTasksInteractive, Show-PmcOverdueTasksInteractive, Show-PmcAgendaInteractive, Show-PmcProjectsInteractive, Show-PmcAllTasksInteractive, Show-PmcTomorrowTasksInteractive, Show-PmcUpcomingTasksInteractive, Show-PmcBlockedTasksInteractive, Show-PmcTasksWithoutDueDateInteractive, Show-PmcNextTasksInteractive, Show-PmcWeekTasksInteractive, Show-PmcMonthTasksInteractive, Register-PmcUniversalCommands, Get-PmcUniversalCommands


# END FILE: ./module/Pmc.Strict/src/UniversalDisplay.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/src/Views.ps1
# SIZE: 9.15 KB
# MODIFIED: 2025-09-24 04:57:28
# ================================================================================

# Views.ps1 - Task view functions updated for current PMC system

function Show-PmcTodayTasks {
    param($Context)

    try {
        $allData = Get-PmcAllData
        $today = (Get-Date).Date

        # Filter tasks due today
        $todayTasks = @($allData.tasks | Where-Object {
            $_.status -eq 'pending' -and $_.due -and
            [datetime]::ParseExact($_.due, 'yyyy-MM-dd', $null).Date -eq $today
        })

        Show-PmcCustomGrid -Domain 'task' -Data $todayTasks -Title "📅 Tasks Due Today" -Interactive

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error showing today's tasks: $_"
    }
}

function Show-PmcTomorrowTasks {
    param($Context)

    try {
        $allData = Get-PmcAllData
        $tomorrow = (Get-Date).Date.AddDays(1)

        # Filter tasks due tomorrow
        $tomorrowTasks = @($allData.tasks | Where-Object {
            $_.status -eq 'pending' -and $_.due -and
            [datetime]::ParseExact($_.due, 'yyyy-MM-dd', $null).Date -eq $tomorrow
        })

        Show-PmcCustomGrid -Domain 'task' -Data $tomorrowTasks -Title "📅 Tasks Due Tomorrow" -Interactive

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error showing tomorrow's tasks: $_"
    }
}

function Show-PmcOverdueTasks {
    param($Context)

    try {
        $allData = Get-PmcAllData
        $today = (Get-Date).Date

        # Filter overdue tasks
        $overdueTasks = @($allData.tasks | Where-Object {
            $_.status -eq 'pending' -and $_.due -and
            [datetime]::ParseExact($_.due, 'yyyy-MM-dd', $null).Date -lt $today
        })

        Show-PmcCustomGrid -Domain 'task' -Data $overdueTasks -Title "⚠️ Overdue Tasks" -Interactive

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error showing overdue tasks: $_"
    }
}

function Show-PmcUpcomingTasks {
    param($Context)

    try {
        $allData = Get-PmcAllData
        $today = (Get-Date).Date
        $nextWeek = $today.AddDays(7)

        # Filter upcoming tasks (next 7 days)
        $upcomingTasks = @($allData.tasks | Where-Object {
            $_.status -eq 'pending' -and $_.due -and {
                $dueDate = [datetime]::ParseExact($_.due, 'yyyy-MM-dd', $null).Date
                $dueDate -gt $today -and $dueDate -le $nextWeek
            }
        })

        Show-PmcCustomGrid -Domain 'task' -Data $upcomingTasks -Title "📆 Upcoming Tasks (Next 7 Days)" -Interactive

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error showing upcoming tasks: $_"
    }
}

function Show-PmcBlockedTasks {
    param($Context)

    try {
        $allData = Get-PmcAllData

        # Filter blocked tasks (tasks with dependencies)
        $blockedTasks = @($allData.tasks | Where-Object {
            $_.status -eq 'pending' -and $_.depends -and $_.depends.Count -gt 0
        })

        Show-PmcCustomGrid -Domain 'task' -Data $blockedTasks -Title "🚫 Blocked Tasks" -Interactive

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error showing blocked tasks: $_"
    }
}

function Show-PmcNoDueDateTasks {
    param($Context)

    try {
        $allData = Get-PmcAllData

        # Filter tasks with no due date
        $noDueTasks = @($allData.tasks | Where-Object {
            $_.status -eq 'pending' -and (-not $_.due -or $_.due -eq '')
        })

        Show-PmcCustomGrid -Domain 'task' -Data $noDueTasks -Title "📋 Tasks Without Due Date" -Interactive

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error showing tasks without due date: $_"
    }
}

function Show-PmcWeekTasksInteractive {
    param($Context)

    try {
        $allData = Get-PmcAllData
        $today = (Get-Date).Date
        $endOfWeek = $today.AddDays(6)

        # Filter tasks for this week
        $weekTasks = @($allData.tasks | Where-Object {
            $_.status -eq 'pending' -and $_.due -and {
                $dueDate = [datetime]::ParseExact($_.due, 'yyyy-MM-dd', $null).Date
                $dueDate -ge $today -and $dueDate -le $endOfWeek
            }
        })

        Show-PmcCustomGrid -Domain 'task' -Data $weekTasks -Title "📆 This Week's Tasks" -Interactive

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error showing week's tasks: $_"
    }
}

function Show-PmcMonthTasksInteractive {
    param($Context)

    try {
        $allData = Get-PmcAllData
        $today = (Get-Date).Date
        $endOfMonth = $today.AddDays(29)

        # Filter tasks for this month
        $monthTasks = @($allData.tasks | Where-Object {
            $_.status -eq 'pending' -and $_.due -and {
                $dueDate = [datetime]::ParseExact($_.due, 'yyyy-MM-dd', $null).Date
                $dueDate -ge $today -and $dueDate -le $endOfMonth
            }
        })

        Show-PmcCustomGrid -Domain 'task' -Data $monthTasks -Title "📅 This Month's Tasks" -Interactive

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error showing month's tasks: $_"
    }
}

function Show-PmcProjectList {
    param($Context)

    try {
        $allData = Get-PmcAllData
        $projects = $allData.projects | Where-Object { -not $_.isArchived }

        Show-PmcCustomGrid -Domain 'project' -Data $projects -Title "📁 Active Projects" -Interactive

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error showing projects: $_"
    }
}

function Show-PmcNextActions {
    param($Context)

    try {
        $allData = Get-PmcAllData

        # Get high priority pending tasks
        $nextActions = @($allData.tasks | Where-Object {
            $_.status -eq 'pending' -and $_.priority -gt 0
        } | Sort-Object priority -Descending | Select-Object -First 10)

        Show-PmcCustomGrid -Domain 'task' -Data $nextActions -Title "⭐ Next Actions (Top 10)" -Interactive

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error showing next actions: $_"
    }
}

# Add Interactive aliases for CommandMap compatibility
function Show-PmcTodayTasksInteractive { param($Context); Show-PmcTodayTasks -Context $Context }
function Show-PmcTomorrowTasksInteractive { param($Context); Show-PmcTomorrowTasks -Context $Context }
function Show-PmcOverdueTasksInteractive { param($Context); Show-PmcOverdueTasks -Context $Context }
function Show-PmcUpcomingTasksInteractive { param($Context); Show-PmcUpcomingTasks -Context $Context }
function Show-PmcBlockedTasksInteractive { param($Context); Show-PmcBlockedTasks -Context $Context }
function Show-PmcTasksWithoutDueDateInteractive { param($Context); Show-PmcNoDueDateTasks -Context $Context }
function Show-PmcProjectsInteractive { param($Context); Show-PmcProjectList -Context $Context }
function Show-PmcNextTasksInteractive { param($Context); Show-PmcNextActions -Context $Context }

# Direct aliases for CommandMap compatibility
function Show-PmcTasksWithoutDueDate { param($Context); Show-PmcNoDueDateTasks -Context $Context }

function Show-PmcKanban {
    param($Context)

    try {
        $allData = Get-PmcAllData

        # Group tasks by status into columns
        $todoTasks = @($allData.tasks | Where-Object { $_.status -eq 'pending' -and (-not $_.due -or (Get-Date $_.due) -gt (Get-Date)) })
        $doingTasks = @($allData.tasks | Where-Object { $_.status -eq 'active' })
        $doneTasks = @($allData.tasks | Where-Object { $_.status -eq 'completed' } | Select-Object -First 10)

        Write-PmcStyled -Style 'Header' -Text "`n🗂️  PMC Kanban Board`n"

        # Display columns side by side
        Write-PmcStyled -Style 'Subheader' -Text "📝 TODO ($($todoTasks.Count))"
        Write-PmcStyled -Style 'Info' -Text "────────────────────"
        foreach ($task in $todoTasks) {
            $priority = if ($task.priority -gt 0) { "⭐" } else { "  " }
            $due = if ($task.due) { " 📅$($task.due)" } else { "" }
            Write-PmcStyled -Style 'Task' -Text "$priority $($task.title)$due"
        }

        Write-PmcStyled -Style 'Subheader' -Text "`n🔄 DOING ($($doingTasks.Count))"
        Write-PmcStyled -Style 'Info' -Text "────────────────────"
        foreach ($task in $doingTasks) {
            $priority = if ($task.priority -gt 0) { "⭐" } else { "  " }
            Write-PmcStyled -Style 'ActiveTask' -Text "$priority $($task.title)"
        }

        Write-PmcStyled -Style 'Subheader' -Text "`n✅ DONE ($($doneTasks.Count))"
        Write-PmcStyled -Style 'Info' -Text "────────────────────"
        foreach ($task in $doneTasks) {
            Write-PmcStyled -Style 'CompletedTask' -Text "   $($task.title)"
        }

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error showing Kanban board: $_"
    }
}

# Export view functions
Export-ModuleMember -Function Show-PmcTodayTasks, Show-PmcTomorrowTasks, Show-PmcOverdueTasks, Show-PmcUpcomingTasks, Show-PmcBlockedTasks, Show-PmcNoDueDateTasks, Show-PmcWeekTasksInteractive, Show-PmcMonthTasksInteractive, Show-PmcProjectList, Show-PmcNextActions, Show-PmcTodayTasksInteractive, Show-PmcTomorrowTasksInteractive, Show-PmcOverdueTasksInteractive, Show-PmcUpcomingTasksInteractive, Show-PmcBlockedTasksInteractive, Show-PmcTasksWithoutDueDateInteractive, Show-PmcProjectsInteractive, Show-PmcNextTasksInteractive, Show-PmcTasksWithoutDueDate, Show-PmcKanban

# END FILE: ./module/Pmc.Strict/src/Views.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/UI/DifferentialRenderer.ps1
# SIZE: 17.55 KB
# MODIFIED: 2025-09-22 13:13:20
# ================================================================================

# PMC Differential Renderer - Flicker-free screen updates
# Only updates changed screen regions for smooth, responsive UI

Set-StrictMode -Version Latest

# Represents a single character cell on the screen
class PmcScreenCell {
    [char] $Character = ' '
    [string] $ForegroundColor = ''
    [string] $BackgroundColor = ''
    [bool] $Bold = $false
    [bool] $Italic = $false
    [bool] $Underline = $false

    PmcScreenCell() {}

    PmcScreenCell([char]$char) {
        $this.Character = $char
    }

    PmcScreenCell([char]$char, [string]$fg, [string]$bg) {
        $this.Character = $char
        $this.ForegroundColor = $fg
        $this.BackgroundColor = $bg
    }

    [bool] Equals([object]$other) {
        if ($null -eq $other) { return $false }
        return ($this.Character -eq $other.Character -and
                $this.ForegroundColor -eq $other.ForegroundColor -and
                $this.BackgroundColor -eq $other.BackgroundColor -and
                $this.Bold -eq $other.Bold -and
                $this.Italic -eq $other.Italic -and
                $this.Underline -eq $other.Underline)
    }

    [string] ToAnsiString() {
        $ansi = ""

        # Build ANSI escape sequence
        $codes = @()

        if ($this.Bold) { $codes += "1" }
        if ($this.Italic) { $codes += "3" }
        if ($this.Underline) { $codes += "4" }

        if ($this.ForegroundColor) {
            switch ($this.ForegroundColor.ToLower()) {
                'black' { $codes += "30" }
                'red' { $codes += "31" }
                'green' { $codes += "32" }
                'yellow' { $codes += "33" }
                'blue' { $codes += "34" }
                'magenta' { $codes += "35" }
                'cyan' { $codes += "36" }
                'white' { $codes += "37" }
                'gray' { $codes += "90" }
                'brightred' { $codes += "91" }
                'brightgreen' { $codes += "92" }
                'brightyellow' { $codes += "93" }
                'brightblue' { $codes += "94" }
                'brightmagenta' { $codes += "95" }
                'brightcyan' { $codes += "96" }
                'brightwhite' { $codes += "97" }
                default {
                    # Try to parse as RGB hex color
                    if ($this.ForegroundColor.StartsWith('#') -and $this.ForegroundColor.Length -eq 7) {
                        $r = [Convert]::ToInt32($this.ForegroundColor.Substring(1,2), 16)
                        $g = [Convert]::ToInt32($this.ForegroundColor.Substring(3,2), 16)
                        $b = [Convert]::ToInt32($this.ForegroundColor.Substring(5,2), 16)
                        $codes += "38;2;$r;$g;$b"
                    }
                }
            }
        }

        if ($this.BackgroundColor) {
            switch ($this.BackgroundColor.ToLower()) {
                'black' { $codes += "40" }
                'red' { $codes += "41" }
                'green' { $codes += "42" }
                'yellow' { $codes += "43" }
                'blue' { $codes += "44" }
                'magenta' { $codes += "45" }
                'cyan' { $codes += "46" }
                'white' { $codes += "47" }
                'gray' { $codes += "100" }
                'brightred' { $codes += "101" }
                'brightgreen' { $codes += "102" }
                'brightyellow' { $codes += "103" }
                'brightblue' { $codes += "104" }
                'brightmagenta' { $codes += "105" }
                'brightcyan' { $codes += "106" }
                'brightwhite' { $codes += "107" }
                default {
                    # Try to parse as RGB hex color
                    if ($this.BackgroundColor.StartsWith('#') -and $this.BackgroundColor.Length -eq 7) {
                        $r = [Convert]::ToInt32($this.BackgroundColor.Substring(1,2), 16)
                        $g = [Convert]::ToInt32($this.BackgroundColor.Substring(3,2), 16)
                        $b = [Convert]::ToInt32($this.BackgroundColor.Substring(5,2), 16)
                        $codes += "48;2;$r;$g;$b"
                    }
                }
            }
        }

        if ($codes.Count -gt 0) {
            $ansi = "`e[$($codes -join ';')m"
        }

        return "$ansi$($this.Character)"
    }

    [string] ToString() {
        return $this.Character
    }
}

# Screen buffer that tracks all character cells
class PmcScreenBuffer {
    hidden [object] $_buffer
    hidden [int] $_width
    hidden [int] $_height
    hidden [bool] $_initialized = $false

    PmcScreenBuffer([int]$width, [int]$height) {
        $this._width = $width
        $this._height = $height
        $this.InitializeBuffer()
        $this._initialized = $true
    }

    [void] InitializeBuffer() {
        $this._buffer = @()
        for ($y = 0; $y -lt $this._height; $y++) {
            $row = @()
            for ($x = 0; $x -lt $this._width; $x++) {
                $row += [PmcScreenCell]::new()
            }
            $this._buffer += ,$row
        }
    }


    [void] Resize([int]$newWidth, [int]$newHeight) {
        if ($newWidth -eq $this._width -and $newHeight -eq $this._height) {
            return  # No change needed
        }

        $oldBuffer = $this._buffer
        $this._width = $newWidth
        $this._height = $newHeight
        $this.InitializeBuffer()

        # Copy existing content where possible
        if ($oldBuffer) {
            $copyHeight = [Math]::Min($oldBuffer.Length, $this._height)
            for ($y = 0; $y -lt $copyHeight; $y++) {
                $copyWidth = [Math]::Min($oldBuffer[$y].Length, $this._width)
                for ($x = 0; $x -lt $copyWidth; $x++) {
                    $this._buffer[$y][$x] = $oldBuffer[$y][$x]
                }
            }
        }
    }

    [object] GetCell([int]$x, [int]$y) {
        if (-not $this._initialized -or $x -lt 0 -or $y -lt 0 -or $x -ge $this._width -or $y -ge $this._height) {
            return [PmcScreenCell]::new()
        }
        return $this._buffer[$y][$x]
    }

    [void] SetCell([int]$x, [int]$y, [object]$cell) {
        if (-not $this._initialized -or $x -lt 0 -or $y -lt 0 -or $x -ge $this._width -or $y -ge $this._height) {
            return  # Out of bounds
        }
        $this._buffer[$y][$x] = $cell
    }

    [void] SetText([int]$x, [int]$y, [string]$text) {
        $this.SetText($x, $y, $text, '', '')
    }

    [void] SetText([int]$x, [int]$y, [string]$text, [string]$foregroundColor, [string]$backgroundColor) {
        if (-not $this._initialized -or $y -lt 0 -or $y -ge $this._height) {
            return
        }

        for ($i = 0; $i -lt $text.Length; $i++) {
            $cellX = $x + $i
            if ($cellX -ge $this._width) { break }

            $cell = [PmcScreenCell]::new($text[$i], $foregroundColor, $backgroundColor)
            $this.SetCell($cellX, $y, $cell)
        }
    }

    [void] Clear() {
        if (-not $this._initialized) { return }

        for ($y = 0; $y -lt $this._height; $y++) {
            for ($x = 0; $x -lt $this._width; $x++) {
                $this._buffer[$y][$x] = [PmcScreenCell]::new()
            }
        }
    }

    [void] ClearRegion([int]$x, [int]$y, [int]$width, [int]$height) {
        if (-not $this._initialized) { return }

        $endX = [Math]::Min($x + $width, $this._width)
        $endY = [Math]::Min($y + $height, $this._height)

        for ($row = $y; $row -lt $endY; $row++) {
            for ($col = $x; $col -lt $endX; $col++) {
                $this._buffer[$row][$col] = [PmcScreenCell]::new()
            }
        }
    }

    [int] GetWidth() { return $this._width }
    [int] GetHeight() { return $this._height }
}

# Change tracking for efficient updates
class PmcScreenDiff {
    [hashtable] $ChangedRegions = @{}  # Key: "x,y", Value: PmcScreenCell
    [bool] $FullRefresh = $false

    [void] AddChange([int]$x, [int]$y, [object]$cell) {
        $key = "$x,$y"
        $this.ChangedRegions[$key] = $cell
    }

    [void] Clear() {
        $this.ChangedRegions.Clear()
        $this.FullRefresh = $false
    }

    [bool] HasChanges() {
        return $this.FullRefresh -or $this.ChangedRegions.Count -gt 0
    }
}

# Main differential renderer class
class PmcDifferentialRenderer {
    hidden [object] $_frontBuffer    # Currently displayed
    hidden [object] $_backBuffer     # Being prepared
    hidden [PmcScreenDiff] $_diff
    hidden [bool] $_initialized = $false
    hidden [string] $_lastAnsiState = ""
    hidden [int] $_lastCursorX = -1
    hidden [int] $_lastCursorY = -1
    hidden [int] $_desiredCursorX = -1
    hidden [int] $_desiredCursorY = -1

    # Performance tracking
    hidden [datetime] $_lastRender = [datetime]::Now
    hidden [int] $_renderCount = 0
    hidden [double] $_totalRenderTime = 0

    PmcDifferentialRenderer([int]$width, [int]$height) {
        $this._frontBuffer = [PmcScreenBuffer]::new($width, $height)
        $this._backBuffer = [PmcScreenBuffer]::new($width, $height)
        $this._diff = [PmcScreenDiff]::new()
        $this._initialized = $true
    }

    # Get the back buffer for drawing operations
    [PmcScreenBuffer] GetDrawBuffer() {
        return $this._backBuffer
    }

    # Resize both buffers
    [void] Resize([int]$newWidth, [int]$newHeight) {
        if (-not $this._initialized) { return }

        $this._frontBuffer.Resize($newWidth, $newHeight)
        $this._backBuffer.Resize($newWidth, $newHeight)
        $this._diff.FullRefresh = $true
    }

    # Calculate differences between front and back buffers
    [void] CalculateDifferences() {
        if (-not $this._initialized) { return }

        $this._diff.Clear()

        $width = $this._backBuffer.GetWidth()
        $height = $this._backBuffer.GetHeight()

        for ($y = 0; $y -lt $height; $y++) {
            for ($x = 0; $x -lt $width; $x++) {
                $frontCell = $this._frontBuffer.GetCell($x, $y)
                $backCell = $this._backBuffer.GetCell($x, $y)

                if (-not $frontCell.Equals($backCell)) {
                    $this._diff.AddChange($x, $y, $backCell)
                }
            }
        }
    }

    # Render only the differences to the console
    [void] RenderDifferences() {
        if (-not $this._initialized -or -not $this._diff.HasChanges()) {
            return
        }

        $startTime = Get-Date

        try {
            if ($this._diff.FullRefresh) {
                $this.RenderFullScreen()
            } else {
                $this.RenderChangedCells()
            }

            # Swap buffers
            $temp = $this._frontBuffer
            $this._frontBuffer = $this._backBuffer
            $this._backBuffer = $temp

            $this._diff.Clear()

        } finally {
            # Performance tracking
            $renderTime = ((Get-Date) - $startTime).TotalMilliseconds
            $this._totalRenderTime += $renderTime
            $this._renderCount++
            $this._lastRender = Get-Date

            Write-PmcDebug -Level 3 -Category 'DifferentialRenderer' -Message "Render completed" -Data @{
                RenderTime = "$([Math]::Round($renderTime, 2))ms"
                ChangedCells = $this._diff.ChangedRegions.Count
                FullRefresh = $this._diff.FullRefresh
            }
            # Position the real cursor if requested
            if ($this._desiredCursorX -ge 0 -and $this._desiredCursorY -ge 0) {
                $this.MoveCursor($this._desiredCursorX, $this._desiredCursorY)
                # ensure cursor visible at prompt
                Write-Host "`e[?25h" -NoNewline
            }
        }
    }

    [void] RenderFullScreen() {
        # Clear screen and reset cursor
        Write-Host "`e[2J`e[H" -NoNewline
        Write-Host "`e[?25l" -NoNewline  # Hide cursor

        $this._lastAnsiState = ""
        $this._lastCursorX = 0
        $this._lastCursorY = 0

        $width = $this._backBuffer.GetWidth()
        $height = $this._backBuffer.GetHeight()

        for ($y = 0; $y -lt $height; $y++) {
            $this.MoveCursor(0, $y)
            $lineOutput = ""

            for ($x = 0; $x -lt $width; $x++) {
                $cell = $this._backBuffer.GetCell($x, $y)
                $lineOutput += $cell.ToAnsiString()
            }

            Write-Host $lineOutput -NoNewline
        }

        Write-Host "`e[0m" -NoNewline  # Reset all formatting
        $this._lastAnsiState = ""
    }

    [void] RenderChangedCells() {
        # Group adjacent changes into runs for efficiency
        $sortedChanges = $this._diff.ChangedRegions.GetEnumerator() | Sort-Object {
            $coords = $_.Key.Split(',')
            [int]$coords[1] * 10000 + [int]$coords[0]  # Sort by row, then column
        }

        $currentRow = -1
        $rowChanges = @()

        foreach ($change in $sortedChanges) {
            $coords = $change.Key.Split(',')
            $x = [int]$coords[0]
            $y = [int]$coords[1]

            if ($y -ne $currentRow) {
                # Process previous row
                if ($rowChanges.Count -gt 0) {
                    $this.RenderRowChanges($currentRow, $rowChanges)
                }

                # Start new row
                $currentRow = $y
                $rowChanges = @()
            }

            $rowChanges += @{ X = $x; Cell = $change.Value }
        }

        # Process final row
        if ($rowChanges.Count -gt 0) {
            $this.RenderRowChanges($currentRow, $rowChanges)
        }

        Write-Host "`e[0m" -NoNewline  # Reset formatting
        $this._lastAnsiState = ""
    }

    [void] RenderRowChanges([int]$row, [array]$changes) {
        # Group adjacent cells into runs
        $runs = @()
        $currentRun = $null

        foreach ($change in ($changes | Sort-Object X)) {
            if ($null -eq $currentRun -or $change.X -ne ($currentRun.EndX + 1)) {
                # Start new run
                if ($currentRun) { $runs += $currentRun }
                $currentRun = @{
                    StartX = $change.X
                    EndX = $change.X
                    Cells = @($change.Cell)
                }
            } else {
                # Extend current run
                $currentRun.EndX = $change.X
                $currentRun.Cells += $change.Cell
            }
        }

        if ($currentRun) { $runs += $currentRun }

        # Render each run
        foreach ($run in $runs) {
            $this.MoveCursor($run.StartX, $row)

            $runOutput = ""
            foreach ($cell in $run.Cells) {
                $runOutput += $cell.ToAnsiString()
            }

            Write-Host $runOutput -NoNewline
        }
    }

    [void] MoveCursor([int]$x, [int]$y) {
        if ($x -ne $this._lastCursorX -or $y -ne $this._lastCursorY) {
            Write-Host "`e[$($y + 1);$($x + 1)H" -NoNewline
            $this._lastCursorX = $x
            $this._lastCursorY = $y
        }
    }

    # Main render method - calculates differences and renders
    [void] Render() {
        if (-not $this._initialized) { return }

        $this.CalculateDifferences()
        $this.RenderDifferences()

        # After flushing text, place the hardware cursor if requested
        if ($this._desiredCursorX -ge 0 -and $this._desiredCursorY -ge 0) {
            try {
                $this.MoveCursor($this._desiredCursorX, $this._desiredCursorY)
            } catch { }
        }
    }

    # Force a full screen refresh
    [void] ForceFullRefresh() {
        $this._diff.FullRefresh = $true
        $this.Render()
    }

    # Performance statistics
    [hashtable] GetPerformanceStats() {
        $avgRenderTime = if ($this._renderCount -gt 0) { $this._totalRenderTime / $this._renderCount } else { 0 }

        return @{
            RenderCount = $this._renderCount
            TotalRenderTime = $this._totalRenderTime
            AverageRenderTime = [Math]::Round($avgRenderTime, 2)
            LastRender = $this._lastRender
            BufferSize = "$($this._frontBuffer.GetWidth())x$($this._frontBuffer.GetHeight())"
        }
    }

    # Cleanup
    [void] ShowCursor() {
        Write-Host "`e[?25h" -NoNewline
    }

    [void] HideCursor() {
        Write-Host "`e[?25l" -NoNewline
    }

    [void] Reset() {
        Write-Host "`e[2J`e[H`e[0m`e[?25h" -NoNewline
        $this._lastAnsiState = ""
        $this._lastCursorX = -1
        $this._lastCursorY = -1
    }

    [void] SetDesiredCursor([int]$x, [int]$y) {
        $this._desiredCursorX = [Math]::Max(0, $x)
        $this._desiredCursorY = [Math]::Max(0, $y)
    }
}

# Global instance
$Script:PmcDifferentialRenderer = $null

function Initialize-PmcDifferentialRenderer {
    param(
        [int]$Width = 120,
        [int]$Height = 30
    )

    if ($Script:PmcDifferentialRenderer) {
        Write-Warning "PMC Differential Renderer already initialized"
        return
    }

    try {
        # Get actual terminal dimensions if possible
        if ([Console]::WindowWidth -gt 0) {
            $Width = [Console]::WindowWidth
            $Height = [Console]::WindowHeight
        }
    } catch {
        Write-PmcDebug -Level 2 -Category 'DifferentialRenderer' -Message "Could not get terminal dimensions, using defaults"
    }

    $Script:PmcDifferentialRenderer = [PmcDifferentialRenderer]::new($Width, $Height)
    Write-PmcDebug -Level 2 -Category 'DifferentialRenderer' -Message "Differential renderer initialized ($Width x $Height)"
}

function Get-PmcDifferentialRenderer {
    if (-not $Script:PmcDifferentialRenderer) {
        Initialize-PmcDifferentialRenderer
    }
    return $Script:PmcDifferentialRenderer
}

function Reset-PmcDifferentialRenderer {
    if ($Script:PmcDifferentialRenderer) {
        $Script:PmcDifferentialRenderer.Reset()
        $Script:PmcDifferentialRenderer = $null
    }
}

Export-ModuleMember -Function Initialize-PmcDifferentialRenderer, Get-PmcDifferentialRenderer, Reset-PmcDifferentialRenderer


# END FILE: ./module/Pmc.Strict/UI/DifferentialRenderer.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/UI/EnhancedScreenManager.ps1
# SIZE: 42.07 KB
# MODIFIED: 2025-09-22 14:27:06
# ================================================================================

# PMC Enhanced Screen Manager - Non-blocking unified interface
# Combines command line + navigation + real-time updates

Set-StrictMode -Version Latest

# Screen regions helper class
class PmcScreenRegions {
    [int] $Width
    [int] $Height
    [int] $HeaderHeight = 3
    [int] $StatusHeight = 2
    [int] $CommandHeight = 1

    # Region coordinates
    [object] $Header
    [object] $Content
    [object] $Status
    [object] $Command

    PmcScreenRegions([int]$width, [int]$height) {
        $this.Width = $width
        $this.Height = $height
        $this.InitializeRegions()
    }

    PmcScreenRegions([int]$width, [int]$height, [int]$headerHeight, [int]$statusHeight, [int]$commandHeight) {
        $this.Width = $width
        $this.Height = $height
        $this.HeaderHeight = $headerHeight
        $this.StatusHeight = $statusHeight
        $this.CommandHeight = $commandHeight
        $this.InitializeRegions()
    }

    hidden [void] InitializeRegions() {
        $contentHeight = [Math]::Max(0, $this.Height - $this.HeaderHeight - $this.StatusHeight - $this.CommandHeight)
        $this.Header = [PSCustomObject]@{ X=0; Y=0; Width=$this.Width; Height=$this.HeaderHeight }
        $this.Content = [PSCustomObject]@{ X=0; Y=$this.HeaderHeight; Width=$this.Width; Height=$contentHeight }
        $this.Status = [PSCustomObject]@{ X=0; Y=($this.Height - $this.StatusHeight - $this.CommandHeight); Width=$this.Width; Height=$this.StatusHeight }
        $this.Command = [PSCustomObject]@{ X=0; Y=($this.Height - $this.CommandHeight); Width=$this.Width; Height=$this.CommandHeight }
    }

    [int] GetContentHeight() {
        return $this.Height - $this.HeaderHeight - $this.StatusHeight - $this.CommandHeight
    }
}

# UI mode + interaction enums/state
enum PmcUIMode {
    Command = 0
    UI = 1
}

enum PmcUIInteract {
    Browse = 0
    Edit = 1
}

class PmcUIState {
    [PmcUIMode] $Mode = [PmcUIMode]::Command
    [PmcUIInteract] $UIState = [PmcUIInteract]::Browse
    [string] $CommandBuffer = ''
    [int] $CommandCursor = 0
    [int] $SelectedRow = 0
    [int] $SelectedColumn = 0
    [string] $EditText = ''
    [int] $EditCursor = 0
}

# Enhanced screen manager that orchestrates all UI components
class PmcEnhancedScreenManager {
    # Core components
    hidden [PmcDifferentialRenderer] $_renderer
    hidden [PmcUnifiedDataViewer] $_dataViewer
    hidden [PmcScreenRegions] $_regions

    # State management
    hidden [bool] $_active = $false
    hidden [bool] $_initialized = $false
    hidden [datetime] $_lastRefresh = [datetime]::Now

    # Command line state
    hidden [string] $_commandBuffer = ""
    hidden [int] $_commandCursorPos = 0
    hidden [string] $_lastCommand = ""

    # Screen layout
    hidden [string] $_headerText = "PMC - Enhanced Project Management Console"
    hidden [string] $_promptText = "pmc> "
    hidden [bool]   $_headerDirty = $true
    hidden [int] $_preferredHeaderHeight = 0
    hidden [int] $_preferredStatusHeight = 2
    hidden [int] $_preferredCommandHeight = 1

    # Bar colors (configurable)
    hidden [string] $_headerBg = 'blue'
    hidden [string] $_statusBg = 'black'

    # Performance tracking
    hidden [int] $_frameCount = 0
    hidden [datetime] $_sessionStart = [datetime]::Now

    # Resize debounce
    hidden [datetime] $_lastResizeChange = [datetime]::MinValue
    hidden [int] $_pendingWidth = 0
    hidden [int] $_pendingHeight = 0
    hidden [int] $_resizeDebounceMs = 120

    # Event handlers for integration with existing PMC
    [scriptblock] $CommandProcessor = $null
    [scriptblock] $CompletionProvider = $null

    # Query helper overlay state
    hidden [bool] $_queryHelperActive = $false
    hidden [string] $_queryHelperDomain = 'task'
    hidden [object[]] $_queryHelperItems = @()
    hidden [int] $_queryHelperIndex = 0
    # New unified UI state
    hidden [PmcUIState] $_ui = [PmcUIState]::new()
    # Single toggle: Ctrl+Backtick (ConsoleKey.Oem3)

    PmcEnhancedScreenManager() {
        try {
            $this.InitializeComponents()
            $this.LoadBarColors()
            $this._initialized = $true
        } catch {
            "ERROR in constructor: $($_.Exception.Message)" | Out-File -FilePath "/tmp/pmc-debug.log" -Append
            "ERROR at line: $($_.InvocationInfo.ScriptLineNumber)" | Out-File -FilePath "/tmp/pmc-debug.log" -Append
            throw
        }
    }

    [void] LoadBarColors() {
        try {
            if (Get-Command Get-PmcConfig -ErrorAction SilentlyContinue) {
                $disp = Get-PmcConfig -Section 'Display'
                if ($disp -and $disp.Bars) {
                    if ($disp.Bars.HeaderBg) { $this._headerBg = [string]$disp.Bars.HeaderBg }
                    if ($disp.Bars.StatusBg) { $this._statusBg = [string]$disp.Bars.StatusBg }
                }
            }
        } catch { }
    }

    [void] SetHeaderText([string]$text) {
        if ($null -eq $text) { return }
        if ($this._headerText -ne $text) {
            $this._headerText = $text
            $this._headerDirty = $true
        }
    }

    [void] InitializeComponents() {
        try {
            # Initialize renderer
            $this._renderer = Get-PmcDifferentialRenderer
            if (-not $this._renderer) {
                Initialize-PmcDifferentialRenderer
                $this._renderer = Get-PmcDifferentialRenderer
            }

            # Calculate screen regions
            $width = $this._renderer.GetDrawBuffer().GetWidth()
            $height = $this._renderer.GetDrawBuffer().GetHeight()
            $this._regions = [PmcScreenRegions]::new($width, $height, $this._preferredHeaderHeight, $this._preferredStatusHeight, $this._preferredCommandHeight)
            # Legacy init debug removed

            # Initialize data viewer - always reset to ensure proper bounds
            Reset-PmcUnifiedDataViewer
            Initialize-PmcUnifiedDataViewer -Bounds $this._regions.Content
            $this._dataViewer = Get-PmcUnifiedDataViewer
            # Legacy debug removed

            # Set data viewer renderer
            $this._dataViewer.SetRenderer($this._renderer)

            Write-PmcDebug -Level 2 -Category 'EnhancedScreenManager' -Message "Enhanced screen manager components initialized"

        } catch {
            Write-PmcDebug -Level 1 -Category 'EnhancedScreenManager' -Message "Component initialization failed: $_"
            throw
        }
    }

    hidden [bool] HasRegionProps([object]$region) {
        try {
            $null = $region.X; $null = $region.Y; $null = $region.Width; $null = $region.Height
            return $true
        } catch { return $false }
    }

    hidden [void] EnsureRegions([PmcScreenBuffer]$buffer = $null) {
        if (-not $buffer) { $buffer = $this._renderer.GetDrawBuffer() }
        $needsRebuild = $false
        try { if (-not $this.HasRegionProps($this._regions.Header)) { $needsRebuild = $true } } catch { $needsRebuild = $true }
        try { if (-not $this.HasRegionProps($this._regions.Content)) { $needsRebuild = $true } } catch { $needsRebuild = $true }
        try { if (-not $this.HasRegionProps($this._regions.Status)) { $needsRebuild = $true } } catch { $needsRebuild = $true }
        try { if (-not $this.HasRegionProps($this._regions.Command)) { $needsRebuild = $true } } catch { $needsRebuild = $true }
        if ($needsRebuild) {
            try {
                $w = $buffer.GetWidth(); $h = $buffer.GetHeight()
                $this._regions = [PmcScreenRegions]::new($w, $h, $this._preferredHeaderHeight, $this._preferredStatusHeight, $this._preferredCommandHeight)
                $this._headerDirty = $true
                # Legacy debug removed
            } catch { }
        }
    }

    [void] SetupInputHandlers() { }

    # Legacy entry rejected — single modal path only
    [void] StartSession() { throw "Use StartModalSession()" }

    # Modal session using blocking input per mode (no background readers)
    [void] StartModalSession() {
        if ($this._active) {
            Write-Warning "Enhanced screen session already active"
            return
        }

        $this._active = $true
        $this._sessionStart = [datetime]::Now

        try {
            # Clear previous temp debug file to avoid stale lines
            try { if (Test-Path "/tmp/pmc-debug.log") { Remove-Item "/tmp/pmc-debug.log" -Force -ErrorAction SilentlyContinue } } catch {}
            $this.Log(2, 'StartModalSession')
            # Clear and initial full compose
            Write-Host "`e[2J`e[H" -NoNewline
            $this._renderer.HideCursor()
            Start-Sleep -Milliseconds 50
            $this.RenderFullInterface()

            # Initial data
            $this._dataViewer.SetDataType("task")
            $this._dataViewer.RefreshData()
            $buf = $this._renderer.GetDrawBuffer()
            $this.RenderDataArea($buf)
            $this.RenderCommandLine($null, $buf)
            $this.RenderStatus($buf)
            $this._renderer.Render()

            $this.EnterCommandFocus()

            while ($this._active) {
                # Resize debounce handling
                try {
                    $buf = $this._renderer.GetDrawBuffer()
                    $bw = $buf.GetWidth(); $bh = $buf.GetHeight()
                    $cw = [Console]::WindowWidth; $ch = [Console]::WindowHeight
                    if ($cw -ne $bw -or $ch -ne $bh) {
                        $this._pendingWidth = $cw; $this._pendingHeight = $ch
                        $this._lastResizeChange = [datetime]::Now
                        $this._headerDirty = $true
                    }
                    if ($this._lastResizeChange -ne [datetime]::MinValue) {
                        $elapsed = ([datetime]::Now - $this._lastResizeChange).TotalMilliseconds
                        if ($elapsed -ge $this._resizeDebounceMs) {
                            $this._renderer.Resize($this._pendingWidth, $this._pendingHeight)
                            $this._regions = [PmcScreenRegions]::new($this._pendingWidth, $this._pendingHeight)
                            if ($this._dataViewer) { $this._dataViewer.SetBounds($this._regions.Content) }
                            $this.RenderFullInterface()
                            $this._renderer.Render()
                            $this._lastResizeChange = [datetime]::MinValue
                        }
                    }
                } catch { }

                if ($this._ui.Mode -eq [PmcUIMode]::Command) { $this.CommandLoop() }
                else { $this.UiLoop() }
            }
        } finally {
            $this.Cleanup()
        }
    }

    # Mode management helpers
    [void] EnterCommandFocus() {
        $this._ui.Mode = [PmcUIMode]::Command
        $this._ui.UIState = [PmcUIInteract]::Browse
        $this.Log(2,'EnterCommandFocus')
        $this.RenderFullInterface()
    }

    [void] EnterUiFocus() {
        $this._ui.Mode = [PmcUIMode]::UI
        $this._ui.UIState = [PmcUIInteract]::Browse
        $this.Log(2,'EnterUiFocus')
        $this.RenderFullInterface()
    }

    [void] CommandLoop() {
        while ($this._active -and $this._ui.Mode -eq [PmcUIMode]::Command) {
            try { $key = [Console]::ReadKey($true) } catch { Start-Sleep -Milliseconds 25; continue }
            if ( ($key.Key -eq [ConsoleKey]::Oem3) -and ($key.Modifiers -band [ConsoleModifiers]::Control) ) { $this.Log(2,'Toggle via Ctrl+`'); $this.EnterUiFocus(); $this.DrainConsoleInput(25); break }
            if ($key.Key -eq [ConsoleKey]::Escape) {
                $seq = $this.TryReadCsiUSequence()
                if ($seq -eq '[96;5u') { $this.Log(2,'Toggle via CSI-u [96;5u]'); $this.EnterUiFocus(); $this.DrainConsoleInput(25); break }
                continue
            }
            if ($key.Key -eq [ConsoleKey]::F10 -or ($key.Key -eq [ConsoleKey]::Q -and ($key.Modifiers -band [ConsoleModifiers]::Control))) { $this.StopSession(); break }

            $state = [PSCustomObject]@{ CommandBuffer = $this._ui.CommandBuffer; CommandCursorPos = $this._ui.CommandCursor }

            $this.HandleCommandLineInput($key, $state)

            $this._ui.CommandBuffer = $state.CommandBuffer
            $this._ui.CommandCursor = $state.CommandCursorPos
            $buf = $this._renderer.GetDrawBuffer()
            $this.RenderCommandLine($state, $buf)
            $this.RenderStatus($buf)
            $this._renderer.Render()
        }
    }

    [void] UiLoop() {
        while ($this._active -and $this._ui.Mode -eq [PmcUIMode]::UI) {
            try { $key = [Console]::ReadKey($true) } catch { Start-Sleep -Milliseconds 25; continue }
            if ( ($key.Key -eq [ConsoleKey]::Oem3) -and ($key.Modifiers -band [ConsoleModifiers]::Control) ) { $this.Log(2,'Toggle via Ctrl+`'); $this.EnterCommandFocus(); $this.DrainConsoleInput(25); break }
            if ($key.Key -eq [ConsoleKey]::Escape) {
                $seq = $this.TryReadCsiUSequence()
                if ($seq -eq '[96;5u') { $this.Log(2,'Toggle via CSI-u [96;5u]'); $this.EnterCommandFocus(); $this.DrainConsoleInput(25); break }
                continue
            }
            if ($key.Key -eq [ConsoleKey]::F10 -or ($key.Key -eq [ConsoleKey]::Q -and ($key.Modifiers -band [ConsoleModifiers]::Control))) { $this.StopSession(); break }

            if ($this._ui.UIState -eq [PmcUIInteract]::Edit) {
                $this.HandleInlineEditLoopKey($key)
                continue
            }

            switch ($key.Key) {
                ([ConsoleKey]::UpArrow)   { $this._dataViewer.MoveSelection(-1) }
                ([ConsoleKey]::DownArrow) { $this._dataViewer.MoveSelection(1) }
                ([ConsoleKey]::PageUp)    { $this._dataViewer.MoveSelection(-10) }
                ([ConsoleKey]::PageDown)  { $this._dataViewer.MoveSelection(10) }
                ([ConsoleKey]::Home)      { $this._dataViewer.MoveSelection(-1000) }
                ([ConsoleKey]::End)       { $this._dataViewer.MoveSelection(1000) }
                ([ConsoleKey]::LeftArrow) { if ($this._ui.SelectedColumn -gt 0) { $this._ui.SelectedColumn-- } }
                ([ConsoleKey]::RightArrow){ $this._ui.SelectedColumn++ }
                ([ConsoleKey]::Enter)     { $this.StartInlineEdit($null) }
                ([ConsoleKey]::F2)        { $this.StartInlineEdit($null) }
                default {
                    if (-not [char]::IsControl($key.KeyChar) -and $key.KeyChar -ne [char]0) { $this.StartInlineEdit([string]$key.KeyChar) }
                }
            }

            $buf = $this._renderer.GetDrawBuffer()
            $this.RenderDataArea($buf)
            $this.RenderCommandLine($null, $buf)
            $this.RenderStatus($buf)
            $this._renderer.Render()
        }
    }

    hidden [string] TryReadCsiUSequence() {
        $s = ''
        $deadline = [datetime]::Now.AddMilliseconds(150)
        while ([datetime]::Now -lt $deadline) {
            try {
                if (-not [Console]::KeyAvailable) { Start-Sleep -Milliseconds 1; continue }
                $k = [Console]::ReadKey($true)
                if ($k.Key -eq [ConsoleKey]::Escape) { continue }
            } catch { break }
            if ($k.KeyChar -eq '[' -and $s -eq '') { $s += '['; continue }
            if ($s.StartsWith('[')) {
                $s += [string]$k.KeyChar
                if ($k.KeyChar -eq 'u') { break }
                continue
            }
            # If not part of CSI-u, stop
            break
        }
        return $s
    }

    hidden [void] DrainConsoleInput([int]$ms = 10) {
        $until = [datetime]::Now.AddMilliseconds([Math]::Max(0,$ms))
        while ([datetime]::Now -lt $until) {
            try {
                while ([Console]::KeyAvailable) { [void][Console]::ReadKey($true) }
            } catch { break }
            Start-Sleep -Milliseconds 1
        }
    }

    [void] StartInlineEdit([string]$seedChar) {
        $this._ui.UIState = [PmcUIInteract]::Edit
        $columns = $this._dataViewer.GetColumnDefinitions()
        if (-not $columns -or $columns.Count -eq 0) { $this._ui.UIState = [PmcUIInteract]::Browse; return }
        $dvState = $this._dataViewer.GetState()
        $content = $this._regions.Content
        $availableWidth = $content.Width - 2
        $widths = $this._dataViewer.CalculateColumnWidths($columns, $availableWidth)

        $colCount = @($columns).Count
        if ($this._ui.SelectedColumn -ge $colCount) { $this._ui.SelectedColumn = [Math]::Max(0, $colCount - 1) }

        $x = $content.X + 1
        for ($i = 0; $i -lt $this._ui.SelectedColumn; $i++) {
            $n = $this.GetColNameSafe($columns[$i])
            if ($n -and $widths.ContainsKey($n)) { $x += $widths[$n] + 1 }
        }
        $colName = $this.GetColNameSafe($columns[$this._ui.SelectedColumn])
        $cellWidth = if ($colName -and $widths.ContainsKey($colName)) { [int]$widths[$colName] } else { 10 }
        $y = $content.Y + 1 + ($dvState.SelectedRow - $dvState.ScrollOffset)

        $item = $this._dataViewer.GetSelectedItem()
        $current = ''
        try { if ($item -and $colName) { $current = [string]$item.($colName) } } catch { $current = '' }

        if ($seedChar) { $this._ui.EditText = $seedChar + $current; $this._ui.EditCursor = [Math]::Min($this._ui.EditText.Length, 1) }
        else { $this._ui.EditText = $current; $this._ui.EditCursor = $this._ui.EditText.Length }

        $buf = $this._renderer.GetDrawBuffer()
        $this.RenderDataArea($buf)
        $this.RenderCommandLine($null, $buf)
        $this.RenderStatus($buf)
        $this._renderer.SetDesiredCursor($x + $this._ui.EditCursor, $y)
        $this._renderer.Render()
    }

    [void] HandleInlineEditLoopKey([ConsoleKeyInfo]$key) {
        $columns = $this._dataViewer.GetColumnDefinitions()
        $dvState = $this._dataViewer.GetState()
        $content = $this._regions.Content
        $availableWidth = $content.Width - 2
        $widths = $this._dataViewer.CalculateColumnWidths($columns, $availableWidth)
        $colName = $this.GetColNameSafe($columns[$this._ui.SelectedColumn])
        $cellWidth = if ($colName -and $widths.ContainsKey($colName)) { [int]$widths[$colName] } else { 10 }
        $x = $content.X + 1
        for ($i = 0; $i -lt $this._ui.SelectedColumn; $i++) {
            $n = $this.GetColNameSafe($columns[$i])
            if ($n -and $widths.ContainsKey($n)) { $x += $widths[$n] + 1 }
        }
        $y = $content.Y + 1 + ($dvState.SelectedRow - $dvState.ScrollOffset)

        switch ($key.Key) {
            ([ConsoleKey]::Enter) { $this.CommitInlineEdit(); return }
            ([ConsoleKey]::Escape){ $this.CancelInlineEdit(); return }
            ([ConsoleKey]::Backspace) {
                if ($this._ui.EditCursor -gt 0) { $this._ui.EditText = $this._ui.EditText.Remove($this._ui.EditCursor - 1, 1); $this._ui.EditCursor-- }
            }
            ([ConsoleKey]::Delete) {
                if ($this._ui.EditCursor -lt $this._ui.EditText.Length) { $this._ui.EditText = $this._ui.EditText.Remove($this._ui.EditCursor, 1) }
            }
            ([ConsoleKey]::LeftArrow) { if ($this._ui.EditCursor -gt 0) { $this._ui.EditCursor-- } }
            ([ConsoleKey]::RightArrow){ if ($this._ui.EditCursor -lt $this._ui.EditText.Length) { $this._ui.EditCursor++ } }
            ([ConsoleKey]::Home)      { $this._ui.EditCursor = 0 }
            ([ConsoleKey]::End)       { $this._ui.EditCursor = $this._ui.EditText.Length }
            default {
                if (-not [char]::IsControl($key.KeyChar) -and $key.KeyChar -ne [char]0) { $this._ui.EditText = $this._ui.EditText.Insert($this._ui.EditCursor, [string]$key.KeyChar); $this._ui.EditCursor++ }
            }
        }

        $buf = $this._renderer.GetDrawBuffer()
        $this.RenderDataArea($buf)
        $this.RenderCommandLine($null, $buf)
        $this.RenderStatus($buf)
        $this._renderer.SetDesiredCursor($x + [Math]::Min($this._ui.EditCursor, [Math]::Max(0,$cellWidth-1)), $y)
        $this._renderer.Render()
    }

    [void] CommitInlineEdit() {
        $columns = $this._dataViewer.GetColumnDefinitions()
        $colName = $this.GetColNameSafe($columns[$this._ui.SelectedColumn])
        $item = $this._dataViewer.GetSelectedItem()
        try { if ($item -and $colName) { $item.($colName) = $this._ui.EditText } } catch { }
        $this._ui.UIState = [PmcUIInteract]::Browse
        $buf = $this._renderer.GetDrawBuffer()
        $this.RenderDataArea($buf)
        $this.RenderCommandLine($null, $buf)
        $this.RenderStatus($buf)
        $this._renderer.Render()
    }

    [void] CancelInlineEdit() {
        $this._ui.UIState = [PmcUIInteract]::Browse
        $buf = $this._renderer.GetDrawBuffer()
        $this.RenderDataArea($buf)
        $this.RenderCommandLine($null, $buf)
        $this.RenderStatus($buf)
        $this._renderer.Render()
    }

    hidden [string] GetColNameSafe([object]$col) {
        if ($null -eq $col) { return '' }
        if ($col -is [hashtable]) { if ($col.ContainsKey('Name')) { return [string]$col['Name'] } }
        if ($col.PSObject.Properties['Name']) { return [string]$col.Name }
        if ($col.PSObject.Properties['Key']) { return [string]$col.Key }
        return ''
    }

    # Removed non-blocking variant — single path only

    [void] StopSession() {
        $this._active = $false
    }

    [void] ProcessInput([ConsoleKeyInfo]$key) { }
    [void] ProcessInputFromString([string]$inputLine) { }

    # Input handlers for different contexts
    [void] HandleCommandLineInput([ConsoleKeyInfo]$key, $state) {
        switch ($key.Key) {
            'Enter' {
                $text = ($state.CommandBuffer ?? '').Trim()
                if ($text) {
                    if ($text -ieq 'help') {
                        $this.Log(2,'Command: help (switching data type to help)')
                        try { $this._dataViewer.SetDataType('help'); $this._dataViewer.RefreshData() } catch {}
                        $state.CommandBuffer = ""
                        $state.CommandCursorPos = 0
                        # Full repaint to stabilize view
                        $this.RenderFullInterface()
                        return
                    }
                    $this.ExecuteCommand($text)
                    $state.CommandBuffer = ""
                    $state.CommandCursorPos = 0
                }
            }
            'Backspace' {
                if ($state.CommandCursorPos -gt 0) {
                    $state.CommandBuffer = $state.CommandBuffer.Remove($state.CommandCursorPos - 1, 1)
                    $state.CommandCursorPos--
                }
            }
            'LeftArrow' {
                if ($state.CommandCursorPos -gt 0) {
                    $state.CommandCursorPos--
                }
            }
            'RightArrow' {
                if ($state.CommandCursorPos -lt $state.CommandBuffer.Length) {
                    $state.CommandCursorPos++
                }
            }
            'UpArrow' {
                return
            }
            'Tab' {
                $this.HandleTabCompletion($state)
            }
            default {
                if (-not [char]::IsControl($key.KeyChar)) {
                    $state.CommandBuffer = $state.CommandBuffer.Insert($state.CommandCursorPos, $key.KeyChar)
                    $state.CommandCursorPos++
                }
            }
        }

        $this.RenderCommandLine($state)
    }

    [void] HandleGridNavigationInput([ConsoleKeyInfo]$key, $state) {
        switch ($key.Key) {
            'UpArrow' { $this._dataViewer.MoveSelection(-1) }
            'DownArrow' { $this._dataViewer.MoveSelection(1) }
            'PageUp' { $this._dataViewer.MoveSelection(-10) }
            'PageDown' { $this._dataViewer.MoveSelection(10) }
            'Home' { $this._dataViewer.MoveSelection(-1000) }
            'End' { $this._dataViewer.MoveSelection(1000) }
            'Enter' {
                $selectedItem = $this._dataViewer.GetSelectedItem()
                if ($selectedItem) {
                    $this.HandleItemSelection($selectedItem)
                }
            }
            'Escape' { $this.EnterCommandFocus(); return }
            default {
                # Letter/number keys for quick search or command
                if ([char]::IsLetterOrDigit($key.KeyChar)) {
                    $state.CommandBuffer = [string]$key.KeyChar
                    $state.CommandCursorPos = 1
                    $this.EnterCommandFocus()
                    $this.RenderCommandLine([pscustomobject]@{ CommandBuffer=$this._ui.CommandBuffer; CommandCursorPos=$this._ui.CommandCursor })
                }
            }
        }
    }

    [void] HandleInlineEditInput([ConsoleKeyInfo]$key, $state) {
        # Placeholder for inline editing
        switch ($key.Key) {
            'Enter' {
                $this._ui.UIState = [PmcUIInteract]::Browse
            }
            'Escape' {
                $this._ui.UIState = [PmcUIInteract]::Browse
            }
        }
    }

    # Command execution
    [void] ExecuteCommand([string]$command) {
        $this._lastCommand = $command
        Write-PmcDebug -Level 2 -Category 'EnhancedScreenManager' -Message "Executing command: '$command'"

        try {
            if ($this.CommandProcessor) {
                & $this.CommandProcessor $command
            } else {
                # Fallback to existing PMC command system
                if (Get-Command Invoke-PmcEnhancedCommand -ErrorAction SilentlyContinue) {
                    Invoke-PmcEnhancedCommand -Command $command
                }
            }

            # Refresh data after command execution
            $this._dataViewer.RefreshData()

        } catch {
            Write-PmcDebug -Level 1 -Category 'EnhancedScreenManager' -Message "Command execution failed: $_"
            # Show error in status area
            $this.ShowError("Command failed: $_")
        }
    }

    [void] HandleTabCompletion($state) {
        if ($this.CompletionProvider) {
            try {
                $completions = & $this.CompletionProvider $state.CommandBuffer $state.CommandCursorPos
                if ($completions -and $completions.Count -gt 0) {
                    # Simple completion - take first match
                    $completion = $completions[0]
                    $state.CommandBuffer = $completion
                    $state.CommandCursorPos = $completion.Length
                    $this.RenderCommandLine($state)
                }
            } catch {
                Write-PmcDebug -Level 2 -Category 'EnhancedScreenManager' -Message "Tab completion failed: $_"
            }
        }
    }

    [void] HandleItemSelection([object]$item) {
        Write-PmcDebug -Level 2 -Category 'EnhancedScreenManager' -Message "Item selected: $($item | ConvertTo-Json -Compress)"
        # Placeholder for item selection handling
    }

    # Rendering methods
    [void] RenderFullInterface() {
        $buffer = $this._renderer.GetDrawBuffer()
        $this.EnsureRegions($buffer)
        $buffer.Clear()

        $this.RenderHeader($buffer)
        $this.RenderDataArea($buffer)
        $this.RenderCommandLine($null, $buffer)
        $this.RenderStatus($buffer)

        # Force render the buffer to screen
        $this._renderer.Render()
    }

    [void] RenderInterface() {
        $this.EnsureRegions()
        $buffer = $this._renderer.GetDrawBuffer()
        if ($this._headerDirty) { $this.RenderHeader($buffer); $this._headerDirty = $false }
        $this.RenderDataArea($buffer)
        $this.RenderCommandLine($null, $buffer)
        $this.RenderStatus($buffer)
    }

    [void] RenderHeader([PmcScreenBuffer]$buffer = $null) {
        try {
            if (-not $buffer) { $buffer = $this._renderer.GetDrawBuffer() }

            $header = $this._regions.Header
            if (-not $this.HasRegionProps($header)) {
                $this.EnsureRegions($buffer)
                $header = $this._regions.Header
            }
            $headerX = $header.X
            $headerY = $header.Y

            if ($this._regions.Header.Height -gt 0 -and $this._headerText) {
                $buffer.SetText($headerX + 2, $headerY, $this._headerText, 'white', $this._headerBg)
            }
        } catch {
            "ERROR in RenderHeader: $($_.Exception.Message)" | Out-File -FilePath "/tmp/pmc-debug.log" -Append
            "ERROR at line: $($_.InvocationInfo.ScriptLineNumber)" | Out-File -FilePath "/tmp/pmc-debug.log" -Append
            throw
        }
    }

    [void] RenderDataArea([PmcScreenBuffer]$buffer = $null) {
        if (-not $buffer) { $buffer = $this._renderer.GetDrawBuffer() }
        # Validate content region
        $content = $this._regions.Content
        if (-not $this.HasRegionProps($content)) {
            try {
                $w = $buffer.GetWidth(); $h = $buffer.GetHeight()
                $this._regions = [PmcScreenRegions]::new($w, $h)
                $content = $this._regions.Content
                # Legacy debug removed
            } catch { }
        }
        if ($this._queryHelperActive) {
            $this.RenderQueryHelper($buffer)
        } else {
            try {
                $this._dataViewer.Render()
            } catch {
                # Draw a simple error message in the content area without crashing
                try {
                    $msg = ("Error: {0}" -f $_.Exception.Message)
                    $buffer.ClearRegion($content.X, $content.Y, $content.Width, $content.Height)
                    $buffer.SetText($content.X + 1, $content.Y, $msg, 'red', 'black')
                    $this.Log(1, ("RenderDataArea error: {0}" -f $_.Exception.Message))
                } catch {}
            }
        }
    }

    [void] RenderQueryHelper([PmcScreenBuffer]$buffer) {
        $content = $this._regions.Content
        # Clear content area
        $buffer.ClearRegion($content.X, $content.Y, $content.Width, $content.Height)
        # Header
        $title = "Query Helper — $($this._queryHelperDomain)"
        $buffer.SetText($content.X + 2, $content.Y, $title, 'yellow', 'black')
        # List
        $maxRows = [Math]::Max(3, $content.Height - 2)
        $start = 0
        $end = [Math]::Min(@($this._queryHelperItems).Count, $start + $maxRows)
        for ($i = $start; $i -lt $end; $i++) {
            $rowY = $content.Y + 1 + ($i - $start)
            $item = $this._queryHelperItems[$i]
            $name = [string]$item.Name
            $tok  = [string]$item.Token
            $line = if ($i -eq $this._queryHelperIndex) { "> $name  [$tok]" } else { "  $name  [$tok]" }
            $fg = if ($i -eq $this._queryHelperIndex) { 'black' } else { 'white' }
            $bg = if ($i -eq $this._queryHelperIndex) { 'cyan' } else { 'black' }
            $buffer.SetText($content.X + 2, $rowY, $line, $fg, $bg)
        }
        # Hint
        $hint = "Enter: insert • Esc: close • ↑/↓: select"
        $buffer.SetText($content.X + 2, $content.Y + $content.Height - 1, $hint, 'cyan', 'black')
    }

    [void] OpenQueryHelper($state) {
        # Determine domain from buffer (q <domain> ...), default to 'task'
        $this._queryHelperDomain = 'task'
        try {
            $parts = ($state.CommandBuffer).Trim().Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)
            if ($parts.Count -ge 2 -and $parts[0] -ieq 'q') { $this._queryHelperDomain = $parts[1].ToLower() }
        } catch {}

        # Build items from field schemas
        $this._queryHelperItems = @()
        try {
            $schemas = Get-PmcFieldSchemasForDomain -Domain $this._queryHelperDomain
            foreach ($name in ($schemas.Keys | Sort-Object)) {
                $token = switch ($name) {
                    'project' { '@' }
                    'tags'    { '#' }
                    'priority'{ 'p' }
                    'due'     { 'due:' }
                    default   { "${name}:" }
                }
                $this._queryHelperItems += [pscustomobject]@{ Name=$name; Token=$token }
            }
        } catch {}
        $this._queryHelperIndex = 0
        $this._queryHelperActive = $true
        # Internal modal only
        # Render overlay
        $this.RenderInterface()
    }

    [void] CloseQueryHelper($state) {
        $this._queryHelperActive = $false
        # Internal modal only
        $this.RenderInterface()
    }

    [void] HandleQueryHelperInput([ConsoleKeyInfo]$key, $state) {
        if (-not $this._queryHelperActive) { return }
        switch ($key.Key) {
            'UpArrow'   { if ($this._queryHelperIndex -gt 0) { $this._queryHelperIndex-- }; $buf=$this._renderer.GetDrawBuffer(); $this.RenderDataArea($buf); $this.RenderCommandLine($null,$buf); $this.RenderStatus($buf); return }
            'DownArrow' { if ($this._queryHelperIndex -lt (@($this._queryHelperItems).Count - 1)) { $this._queryHelperIndex++ }; $buf=$this._renderer.GetDrawBuffer(); $this.RenderDataArea($buf); $this.RenderCommandLine($null,$buf); $this.RenderStatus($buf); return }
            'Escape'    { $this.CloseQueryHelper($state); return }
            'Enter'     {
                if (@($this._queryHelperItems).Count -eq 0) { $this.CloseQueryHelper($state); return }
                $item = $this._queryHelperItems[$this._queryHelperIndex]
                $tok = [string]$item.Token
                # Insert token at cursor
                $before = $state.CommandBuffer.Substring(0, [Math]::Min($state.CommandCursorPos, $state.CommandBuffer.Length))
                $after  = $state.CommandBuffer.Substring([Math]::Min($state.CommandCursorPos, $state.CommandBuffer.Length))
                # For '@' and '#' add directly; others append token
                $insert = $tok
                if ($tok -eq 'p') { $insert = 'p' } # user types number next
                $state.CommandBuffer = ($before + $insert + ' ' + $after).TrimEnd()
                $state.CommandCursorPos = [Math]::Min($state.CommandBuffer.Length, ($before + $insert + ' ').Length)
                $this.CloseQueryHelper($state)
                return
            }
        }
    }

    [void] RenderCommandLine($state = $null, [PmcScreenBuffer]$buffer = $null) {
        if (-not $buffer) { $buffer = $this._renderer.GetDrawBuffer() }
        if (-not $state) {
            $state = [PSCustomObject]@{ CommandBuffer = $this._ui.CommandBuffer; CommandCursorPos = $this._ui.CommandCursor }
        }

        $input = $this._regions.Command
        # Legacy debug removed
        if (-not $this.HasRegionProps($input)) {
            try {
                $w = $buffer.GetWidth(); $h = $buffer.GetHeight()
                $this._regions = [PmcScreenRegions]::new($w, $h)
                $input = $this._regions.Command
                # Legacy debug removed
            } catch { }
        }
        $promptX = $input.X + 1
        $promptY = $input.Y

        # Clear input line
        $buffer.ClearRegion($input.X, $input.Y, $input.Width, 1)

        # Render prompt
        $buffer.SetText($promptX, $promptY, $this._promptText, 'green', 'black')

        # Render command buffer
        $commandX = $promptX + $this._promptText.Length
        $bufText = $state.CommandBuffer
        $curPos  = if ($null -ne $state.CommandCursorPos) { [int]$state.CommandCursorPos } elseif ($state.PSObject.Properties['CommandCursor']) { [int]$state.CommandCursor } else { 0 }
        if ($bufText) { $buffer.SetText($commandX, $promptY, $bufText, 'white', 'black') }

        # Set desired hardware cursor position; renderer will move it after flush
        $cursorX = $commandX + $curPos
        $this._renderer.SetDesiredCursor($cursorX, $promptY)
    }

    # Overloads to avoid ambiguous single-argument calls
    [void] RenderCommandLine() {
        $this.RenderCommandLine($null, $this._renderer.GetDrawBuffer())
    }

    [void] RenderCommandLine([PmcScreenBuffer]$buffer) {
        $this.RenderCommandLine($null, $buffer)
    }

    [void] RenderCommandLine([psobject]$state) {
        $this.RenderCommandLine($state, $this._renderer.GetDrawBuffer())
    }

    [void] RenderStatus([PmcScreenBuffer]$buffer = $null) {
        if (-not $buffer) { $buffer = $this._renderer.GetDrawBuffer() }

        $status = $this._regions.Status
        if (-not $this.HasRegionProps($status)) {
            try {
                $w = $buffer.GetWidth(); $h = $buffer.GetHeight()
                $this._regions = [PmcScreenRegions]::new($w, $h)
                $status = $this._regions.Status
                # Legacy debug removed
            } catch { }
        }
        # Clear the entire status region to avoid bleed/artifacts
        $buffer.ClearRegion($status.X, $status.Y, $status.Width, $status.Height)

        $statusText = "Ready"
        $modeText = if ($this._ui) {
            if ($this._ui.Mode -eq [PmcUIMode]::Command) { 'CMD' }
            elseif ($this._ui.UIState -eq [PmcUIInteract]::Edit) { 'EDIT' }
            else { 'UI' }
        } else {
            'UNK'
        }

        # Frame counter (optional, lightweight)
        $rightText = "Frame: $($this._frameCount)"

        $leftText  = "[$modeText] $statusText"
        $buffer.SetText($status.X + 1, $status.Y, $leftText, 'cyan', $this._statusBg)
        $buffer.SetText([Math]::Max($status.X + $status.Width - $rightText.Length - 2, $status.X + 1), $status.Y, $rightText, 'yellow', $this._statusBg)
    }


    [void] ShowError([string]$message) {
        # Log error without relying on module debug
        $this.Log(1, ("Error: {0}" -f $message))
    }

    [void] Cleanup() {
        try {
            $this._renderer.ShowCursor()
            $this._renderer.Reset()
            Write-PmcDebug -Level 1 -Category 'EnhancedScreenManager' -Message "Enhanced screen session ended"
        } catch {
            Write-PmcDebug -Level 2 -Category 'EnhancedScreenManager' -Message "Cleanup error: $_"
        }
    }

    # Public interface
    [bool] IsActive() { return $this._active }
    [hashtable] GetPerformanceStats() {
        $runtime = ([datetime]::Now - $this._sessionStart).TotalSeconds
        $fps = if ($runtime -gt 0) { $this._frameCount / $runtime } else { 0 }

        return @{
            FrameCount = $this._frameCount
            Runtime = [Math]::Round($runtime, 2)
            FPS = [Math]::Round($fps, 1)
            LastRefresh = $this._lastRefresh
        }
    }
}

# Compatibility shim for old initializer and launcher (exported)
function Initialize-PmcScreen {
    param([string]$Title = "PMC — Project Management Console")
    # No-op in enhanced mode; kept for compatibility with existing initializer
    return $true
}

# Global instance
$Script:PmcEnhancedScreenManager = $null

function Start-PmcEnhancedSession {
    [CmdletBinding()]
    param(
        [switch]$NonBlocking  # Use experimental non-blocking mode
    )


    if ($Script:PmcEnhancedScreenManager -and $Script:PmcEnhancedScreenManager.IsActive()) {
        Write-Warning "Enhanced session already active"
        return
    }

    try {
        # Initialize components
        if (-not $Script:PmcEnhancedScreenManager) {
            $Script:PmcEnhancedScreenManager = [PmcEnhancedScreenManager]::new()

            # Set up integration with existing PMC systems
            $Script:PmcEnhancedScreenManager.CommandProcessor = {
                param([string]$command)
                try {
                    # Sanitize input using PMC security system
                    if (Get-Command Test-PmcInputSafety -ErrorAction SilentlyContinue) {
                        if (-not (Test-PmcInputSafety -Input $command -InputType 'command')) {
                            Write-PmcStyled -Style 'Error' -Text "Input rejected for security reasons"
                            return
                        }
                    }
                    if (Get-Command Invoke-PmcEnhancedCommand -ErrorAction SilentlyContinue) {
                        Invoke-PmcEnhancedCommand -Command $command
                    }
                } catch {
                    Write-PmcDebug -Level 1 -Category 'EnhancedScreenManager' -Message ("Command execution error: {0}" -f $_)
                }
            }

            $Script:PmcEnhancedScreenManager.CompletionProvider = {
                param([string]$buffer, [int]$cursorPos)
                try {
                    $text = $buffer.Substring(0, [Math]::Min($cursorPos, $buffer.Length))
                } catch { $text = $buffer }
                $parts = $text.Trim().Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries)
                if ($parts.Count -eq 0) { return @('q task ') }
                # Basic query completions for 'q'
                if ($parts[0] -ieq 'q') {
                    if ($parts.Count -eq 1) { return @('q task ','q project ','q timelog ') }
                    $domain = $parts[1].ToLower()
                    if ($parts.Count -eq 2) { return @("q $domain @","q $domain #","q $domain p1","q $domain due:today ") }
                    # If last token starts with '@' suggest projects; '#' suggest tags
                    $last = $parts[-1]
                    if ($last.StartsWith('@')) {
                        try { $projs = Get-PmcProjectsData | ForEach-Object { $_.name } | Where-Object { $_ } | Select-Object -Unique | Sort-Object | Select-Object -First 20; return @($projs | ForEach-Object { "q $domain @$($_) " }) } catch {}
                    }
                    if ($last.StartsWith('#')) {
                        try {
                            $tags = @(); foreach ($t in (Get-PmcTasksData)) { if ($t.tags) { foreach ($x in $t.tags) { if ($x) { $tags += [string]$x } } } }
                            $tags = $tags | Select-Object -Unique | Sort-Object | Select-Object -First 20
                            return @($tags | ForEach-Object { "q $domain #$($_) " })
                        } catch {}
                    }
                    return @()
                }
                return @()
            }
        }

        # Single-path session
        $Script:PmcEnhancedScreenManager.StartModalSession()

    } catch {
        Write-Error "Failed to start enhanced session: $_"
        throw
    }
}

function Stop-PmcEnhancedSession {
    if ($Script:PmcEnhancedScreenManager) {
        $Script:PmcEnhancedScreenManager.StopSession()
    }
}

function Get-PmcEnhancedSessionStats {
    if ($Script:PmcEnhancedScreenManager) {
        return $Script:PmcEnhancedScreenManager.GetPerformanceStats()
    }
    return @{}
}

    hidden [void] Log([int]$level, [string]$message) {
        # Write to a temp debug file without relying on module debug implementation
        try { "[$([datetime]::Now.ToString('HH:mm:ss.fff'))] $message" | Out-File -FilePath "/tmp/pmc-debug.log" -Append -Encoding utf8 } catch {}
    }
Export-ModuleMember -Function Start-PmcEnhancedSession, Stop-PmcEnhancedSession, Get-PmcEnhancedSessionStats, Initialize-PmcScreen


# END FILE: ./module/Pmc.Strict/UI/EnhancedScreenManager.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/UI/InputMultiplexer.ps1
# SIZE: 13.62 KB
# MODIFIED: 2025-09-22 13:21:05
# ================================================================================

# PMC Input Multiplexer - Context-Aware Key Routing
# Enables simultaneous command line + navigation without blocking

Set-StrictMode -Version Latest

# Input contexts that can handle different types of keys
enum PmcInputContext {
    CommandLine      # Primary: command input and processing
    GridNavigation   # Secondary: arrow keys, selection in data grids
    InlineEdit       # Tertiary: cell editing within grids
    Modal            # Special: modal dialog input
}

# Input routing configuration
class PmcInputRoutingConfig {
    [hashtable] $ContextPriority = @{
        'Escape' = [PmcInputContext]::CommandLine
        'Ctrl' = [PmcInputContext]::CommandLine
        'Alt' = [PmcInputContext]::CommandLine
        'F1-F12' = [PmcInputContext]::CommandLine
    }

    [hashtable] $GridNavigationKeys = @{
        'UpArrow' = $true
        'DownArrow' = $true
        'LeftArrow' = $true
        'RightArrow' = $true
        'PageUp' = $true
        'PageDown' = $true
        'Home' = $true
        'End' = $true
        'Enter' = $true
    }

    [hashtable] $EditingKeys = @{
        'Backspace' = $true
        'Delete' = $true
        'Insert' = $true
        'Tab' = $true
    }
}

# State for tracking current input mode
class PmcInputState {
    [PmcInputContext] $ActiveContext = [PmcInputContext]::CommandLine
    [bool] $GridBrowseMode = $false          # True when user is actively browsing grid
    [bool] $InlineEditMode = $false          # True when editing a grid cell
    [bool] $ModalActive = $false             # True when modal dialog is open
    [string] $LastCommand = ""               # Last command entered
    [datetime] $LastActivity = [datetime]::Now

    # Command line state
    [string] $CommandBuffer = ""
    [int] $CommandCursorPos = 0

    # Grid state
    [int] $GridSelectedRow = 0
    [int] $GridSelectedColumn = 0
    [string] $GridEditingValue = ""
    [int] $GridEditCursorPos = 0

    [void] Reset() {
        $this.ActiveContext = [PmcInputContext]::CommandLine
        $this.GridBrowseMode = $false
        $this.InlineEditMode = $false
        $this.ModalActive = $false
        $this.CommandBuffer = ""
        $this.CommandCursorPos = 0
    }

    [void] ActivateGridBrowse() {
        $this.GridBrowseMode = $true
        $this.ActiveContext = [PmcInputContext]::GridNavigation
        $this.LastActivity = [datetime]::Now
    }

    [void] ActivateInlineEdit([string]$initialValue) {
        $this.InlineEditMode = $true
        $this.GridEditingValue = $initialValue
        $this.GridEditCursorPos = $initialValue.Length
        $this.ActiveContext = [PmcInputContext]::InlineEdit
        $this.LastActivity = [datetime]::Now
    }

    [void] ReturnToCommandLine() {
        $this.GridBrowseMode = $false
        $this.InlineEditMode = $false
        $this.ActiveContext = [PmcInputContext]::CommandLine
        $this.LastActivity = [datetime]::Now
    }
}

# Main input multiplexer class
class PmcInputMultiplexer {
    hidden [PmcInputRoutingConfig] $_config
    hidden [PmcInputState] $_state
    hidden [hashtable] $_handlers = @{}
    hidden [bool] $_initialized = $false

    # Event handlers for different contexts
    [scriptblock] $CommandLineHandler = $null
    [scriptblock] $GridNavigationHandler = $null
    [scriptblock] $InlineEditHandler = $null
    [scriptblock] $ModalHandler = $null

    PmcInputMultiplexer() {
        $this._config = [PmcInputRoutingConfig]::new()
        $this._state = [PmcInputState]::new()
        $this.InitializeDefaultHandlers()
        $this._initialized = $true
    }

    [void] InitializeDefaultHandlers() {
        # Default command line handler (processes commands)
        $this.CommandLineHandler = {
            param([ConsoleKeyInfo]$key, [PmcInputState]$state)

            switch ($key.Key) {
                'Enter' {
                    if ($state.CommandBuffer.Trim()) {
                        # Process command
                        $this.ProcessCommand($state.CommandBuffer)
                        $state.CommandBuffer = ""
                        $state.CommandCursorPos = 0
                    }
                }
                'Backspace' {
                    if ($state.CommandCursorPos -gt 0) {
                        $state.CommandBuffer = $state.CommandBuffer.Remove($state.CommandCursorPos - 1, 1)
                        $state.CommandCursorPos--
                    }
                }
                'LeftArrow' {
                    if ($state.CommandCursorPos -gt 0) {
                        $state.CommandCursorPos--
                    }
                }
                'RightArrow' {
                    if ($state.CommandCursorPos -lt $state.CommandBuffer.Length) {
                        $state.CommandCursorPos++
                    }
                }
                'Tab' {
                    # Tab completion
                    $this.HandleTabCompletion($state)
                }
                default {
                    if ([char]::IsControl($key.KeyChar)) {
                        return  # Skip control characters
                    }
                    # Insert character at cursor position
                    $state.CommandBuffer = $state.CommandBuffer.Insert($state.CommandCursorPos, $key.KeyChar)
                    $state.CommandCursorPos++
                }
            }

            # Render updated command line
            $this.RenderCommandLine($state)
        }

        # Default grid navigation handler
        $this.GridNavigationHandler = {
            param([ConsoleKeyInfo]$key, [PmcInputState]$state)

            switch ($key.Key) {
                'UpArrow' { $this.MoveGridSelection(0, -1) }
                'DownArrow' { $this.MoveGridSelection(0, 1) }
                'LeftArrow' { $this.MoveGridSelection(-1, 0) }
                'RightArrow' { $this.MoveGridSelection(1, 0) }
                'Enter' { $this.ActivateGridEdit() }
                'F2' { $this.ActivateGridEdit() }
                'Escape' { $state.ReturnToCommandLine(); $this.RenderPrompt() }
                default {
                    # Alphanumeric keys start quick search or edit
                    if ([char]::IsLetterOrDigit($key.KeyChar)) {
                        $state.ActivateInlineEdit([string]$key.KeyChar)
                        $this.RenderInlineEdit($state)
                    }
                }
            }
        }

        # Default inline edit handler
        $this.InlineEditHandler = {
            param([ConsoleKeyInfo]$key, [PmcInputState]$state)

            switch ($key.Key) {
                'Enter' {
                    # Commit edit
                    $this.CommitInlineEdit($state.GridEditingValue)
                    $state.GridBrowseMode = $true
                    $state.InlineEditMode = $false
                    $state.ActiveContext = [PmcInputContext]::GridNavigation
                }
                'Escape' {
                    # Cancel edit
                    $state.GridBrowseMode = $true
                    $state.InlineEditMode = $false
                    $state.ActiveContext = [PmcInputContext]::GridNavigation
                }
                'Backspace' {
                    if ($state.GridEditCursorPos -gt 0) {
                        $state.GridEditingValue = $state.GridEditingValue.Remove($state.GridEditCursorPos - 1, 1)
                        $state.GridEditCursorPos--
                    }
                }
                default {
                    if ([char]::IsControl($key.KeyChar)) {
                        return  # Skip control characters
                    }
                    # Insert character
                    $state.GridEditingValue = $state.GridEditingValue.Insert($state.GridEditCursorPos, $key.KeyChar)
                    $state.GridEditCursorPos++
                }
            }

            $this.RenderInlineEdit($state)
        }
    }

    # Main input routing logic
    [PmcInputContext] RouteKey([ConsoleKeyInfo]$key) {
        if (-not $this._initialized) {
            throw "Input multiplexer not initialized"
        }

        # Priority routing: certain keys always go to command line
        if ($this.IsCommandLinePriorityKey($key)) {
            $this._state.ReturnToCommandLine()
            return [PmcInputContext]::CommandLine
        }

        # Modal has highest priority when active
        if ($this._state.ModalActive) {
            return [PmcInputContext]::Modal
        }

        # Route based on current state and key type
        if ($this._state.InlineEditMode) {
            return [PmcInputContext]::InlineEdit
        }

        if ($this._state.GridBrowseMode -and $this.IsGridNavigationKey($key)) {
            return [PmcInputContext]::GridNavigation
        }

        # Default: everything goes to command line (preserve CLI-first)
        return [PmcInputContext]::CommandLine
    }

    # Handle a key press by routing to appropriate context
    [void] HandleKey([ConsoleKeyInfo]$key) {
        if (-not $this._initialized) {
            throw "Input multiplexer not initialized"
        }

        $context = $this.RouteKey($key)
        # Debug removed
        $this._state.ActiveContext = $context
        $this._state.LastActivity = [datetime]::Now

        # Execute appropriate handler
        try {
            switch ($context) {
                ([PmcInputContext]::CommandLine) {
                    if ($this.CommandLineHandler) {
                        & $this.CommandLineHandler $key $this._state
                    }
                }
                ([PmcInputContext]::GridNavigation) {
                    if ($this.GridNavigationHandler) {
                        & $this.GridNavigationHandler $key $this._state
                    }
                }
                ([PmcInputContext]::InlineEdit) {
                    if ($this.InlineEditHandler) {
                        & $this.InlineEditHandler $key $this._state
                    }
                }
                ([PmcInputContext]::Modal) {
                    if ($this.ModalHandler) {
                        & $this.ModalHandler $key $this._state
                    }
                }
            }
        } catch {
            Write-PmcDebug -Level 1 -Category 'InputMultiplexer' -Message "Handler error in context $context" -Data @{ Error = $_.ToString() }
            # Fallback to command line on error
            $this._state.ReturnToCommandLine()
        }
        # Debug removed
    }

    # Utility methods for key classification
    [bool] IsCommandLinePriorityKey([ConsoleKeyInfo]$key) {
        # Escape always returns to command line
        if ($key.Key -eq 'Escape') { return $true }

        # Ctrl combinations go to command line
        if ($key.Modifiers -band [ConsoleModifiers]::Control) { return $true }

        # Alt combinations go to command line
        if ($key.Modifiers -band [ConsoleModifiers]::Alt) { return $true }

        # Function keys go to command line
        if ($key.Key -ge [ConsoleKey]::F1 -and $key.Key -le [ConsoleKey]::F24) { return $true }

        return $false
    }

    [bool] IsGridNavigationKey([ConsoleKeyInfo]$key) {
        return $this._config.GridNavigationKeys.ContainsKey($key.Key.ToString())
    }

    # State management
    [PmcInputState] GetState() { return $this._state }

    [void] SetGridBrowseMode([bool]$enabled) {
        if ($enabled) {
            $this._state.ActivateGridBrowse()
        } else {
            $this._state.ReturnToCommandLine()
        }
    }

    [void] ResetState() { $this._state.Reset() }

    # Placeholder methods for rendering and command processing (to be implemented)
    [void] ProcessCommand([string]$command) {
        # Will integrate with existing Invoke-PmcCommand
        Write-PmcDebug -Level 2 -Category 'InputMultiplexer' -Message "Processing command: $command"
    }

    [void] HandleTabCompletion([PmcInputState]$state) {
        # Will integrate with existing completion engine
        Write-PmcDebug -Level 3 -Category 'InputMultiplexer' -Message "Tab completion requested"
    }

    [void] RenderCommandLine([PmcInputState]$state) {
        # Will integrate with screen manager
        Write-PmcDebug -Level 3 -Category 'InputMultiplexer' -Message "Rendering command line"
    }

    [void] RenderPrompt() {
        Write-PmcDebug -Level 3 -Category 'InputMultiplexer' -Message "Rendering prompt"
    }

    [void] MoveGridSelection([int]$deltaX, [int]$deltaY) {
        $this._state.GridSelectedRow += $deltaY
        $this._state.GridSelectedColumn += $deltaX
        Write-PmcDebug -Level 3 -Category 'InputMultiplexer' -Message "Grid selection moved to ($($this._state.GridSelectedColumn), $($this._state.GridSelectedRow))"
    }

    [void] ActivateGridEdit() {
        $this._state.ActivateInlineEdit("")
        Write-PmcDebug -Level 3 -Category 'InputMultiplexer' -Message "Grid edit activated"
    }

    [void] RenderInlineEdit([PmcInputState]$state) {
        Write-PmcDebug -Level 3 -Category 'InputMultiplexer' -Message "Rendering inline edit: '$($state.GridEditingValue)'"
    }

    [void] CommitInlineEdit([string]$value) {
        Write-PmcDebug -Level 2 -Category 'InputMultiplexer' -Message "Committing inline edit: '$value'"
    }
}

# Global instance for use by screen manager
$Script:PmcInputMultiplexer = $null

function Initialize-PmcInputMultiplexer {
    if ($Script:PmcInputMultiplexer) {
        Write-Warning "PMC Input Multiplexer already initialized"
        return
    }

    $Script:PmcInputMultiplexer = [PmcInputMultiplexer]::new()
    Write-PmcDebug -Level 2 -Category 'InputMultiplexer' -Message "Input multiplexer initialized"
}

function Get-PmcInputMultiplexer {
    if (-not $Script:PmcInputMultiplexer) {
        Initialize-PmcInputMultiplexer
    }
    return $Script:PmcInputMultiplexer
}

Export-ModuleMember -Function Initialize-PmcInputMultiplexer, Get-PmcInputMultiplexer


# END FILE: ./module/Pmc.Strict/UI/InputMultiplexer.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/UI/KeyReader.ps1
# SIZE: 1.92 KB
# MODIFIED: 2025-09-22 09:40:36
# ================================================================================

Set-StrictMode -Version Latest

# Cross-platform key reader using a background .NET thread and a concurrent queue.
# Avoids reliance on [Console]::KeyAvailable which can be unreliable across hosts.

Add-Type -Language CSharp -TypeDefinition @"
using System;
using System.Collections.Concurrent;
using System.Threading;

public class PmcKeyReader
{
    private readonly ConcurrentQueue<ConsoleKeyInfo> _queue = new ConcurrentQueue<ConsoleKeyInfo>();
    private Thread _readerThread;
    private volatile bool _running = false;

    public void Start()
    {
        if (_running) return;
        _running = true;
        _readerThread = new Thread(() =>
        {
            while (_running)
            {
                try
                {
                    // Blocking read; returns when a key is pressed
                    var key = Console.ReadKey(true);
                    _queue.Enqueue(key);
                }
                catch
                {
                    // If the host doesn't support ReadKey at this moment, back off briefly
                    Thread.Sleep(25);
                }
            }
        });
        _readerThread.IsBackground = true;
        _readerThread.Name = "PmcKeyReader";
        _readerThread.Start();
    }

    public void Stop()
    {
        _running = false;
        try { _readerThread?.Join(200); } catch { }
        _readerThread = null;
        while (_queue.TryDequeue(out _)) {}
    }

    public bool TryRead(out ConsoleKeyInfo key)
    {
        return _queue.TryDequeue(out key);
    }
}
"@

function Get-PmcKeyReader {
    if (-not $Script:PmcKeyReader) {
        $Script:PmcKeyReader = [PmcKeyReader]::new()
        $Script:PmcKeyReader.Start()
    }
    return $Script:PmcKeyReader
}

function Stop-PmcKeyReader {
    if ($Script:PmcKeyReader) {
        $Script:PmcKeyReader.Stop()
        $Script:PmcKeyReader = $null
    }
}

Export-ModuleMember -Function Get-PmcKeyReader, Stop-PmcKeyReader



# END FILE: ./module/Pmc.Strict/UI/KeyReader.ps1


# ================================================================================
# FILE: ./module/Pmc.Strict/UI/UnifiedDataViewer.ps1
# SIZE: 20.57 KB
# MODIFIED: 2025-09-22 14:06:35
# ================================================================================

# PMC Unified Data Viewer - Real-time data display with navigation
# Preserves PMC's existing query language and data structures

Set-StrictMode -Version Latest

# Data viewer state and configuration
class PmcDataViewerState {
    [string] $DataType = "tasks"           # tasks, projects, timelog, help
    [object[]] $Data = @()                 # Current dataset
    [object[]] $FilteredData = @()         # After filtering/sorting
    [hashtable] $Columns = @{}             # Column configuration
    [string] $Query = ""                   # Current query string
    [hashtable] $Filters = @{}             # Active filters

    # View state
    [int] $SelectedRow = 0
    [int] $ScrollOffset = 0
    [int] $VisibleRows = 20
    [string] $SortColumn = ""
    [string] $SortDirection = "asc"

    # Real-time update tracking
    [datetime] $LastUpdate = [datetime]::Now
    [string] $LastDataHash = ""
    [bool] $AutoRefresh = $false
    [int] $RefreshIntervalMs = 1000

    [void] Reset() {
        $this.SelectedRow = 0
        $this.ScrollOffset = 0
        $this.Query = ""
        $this.Filters.Clear()
        $this.LastUpdate = [datetime]::Now
    }

    [void] SetData([object[]]$newData) {
        $this.Data = $newData
        $this.FilteredData = $newData
        $this.SelectedRow = 0
        $this.ScrollOffset = 0
        $this.LastUpdate = [datetime]::Now

        # Calculate hash for change detection
        $this.LastDataHash = $this.CalculateDataHash($newData)
    }

    [string] CalculateDataHash([object[]]$data) {
        if (-not $data -or $data.Count -eq 0) { return "" }

        try {
            $hashInput = ($data | ConvertTo-Json -Compress)
            $hash = [System.Security.Cryptography.SHA256]::Create()
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($hashInput)
            $hashBytes = $hash.ComputeHash($bytes)
            return [Convert]::ToBase64String($hashBytes).Substring(0, 16)
        } catch {
            return [datetime]::Now.Ticks.ToString()
        }
    }

    [bool] HasDataChanged([object[]]$newData) {
        $newHash = $this.CalculateDataHash($newData)
        return $newHash -ne $this.LastDataHash
    }
}

# Main unified data viewer class
class PmcUnifiedDataViewer {
    hidden [PmcDataViewerState] $_state
    hidden [object] $_renderer
    hidden [object] $_bounds
    hidden [hashtable] $_theme = @{}
    hidden [bool] $_initialized = $false

    # Integration with existing PMC systems
    [scriptblock] $QueryExecutor = $null     # Executes PMC queries
    [scriptblock] $DataProvider = $null      # Provides raw data
    [scriptblock] $ColumnProvider = $null    # Provides column definitions

    # Event handlers
    [scriptblock] $OnSelectionChanged = $null
    [scriptblock] $OnDataChanged = $null
    [scriptblock] $OnQueryChanged = $null

    PmcUnifiedDataViewer([object]$bounds) {
        $this._state = [PmcDataViewerState]::new()
        $this._bounds = $bounds
        $this.InitializeTheme()
        $this._initialized = $true
    }

    [void] InitializeTheme() {
        # Get theme from PMC's existing theme system
        try {
            $display = Get-PmcState -Section 'Display' -Key 'Theme' -ErrorAction SilentlyContinue
            if ($display) {
                $this._theme = @{
                    HeaderFg = 'white'
                    HeaderBg = 'blue'
                    SelectedFg = 'black'
                    SelectedBg = 'cyan'
                    NormalFg = 'white'
                    NormalBg = 'black'
                    BorderFg = 'gray'
                    Accent = $display.Hex ?? '#33aaff'
                }
            } else {
                # Fallback theme
                $this._theme = @{
                    HeaderFg = 'white'
                    HeaderBg = 'blue'
                    SelectedFg = 'black'
                    SelectedBg = 'cyan'
                    NormalFg = 'white'
                    NormalBg = 'black'
                    BorderFg = 'gray'
                    Accent = '#33aaff'
                }
            }
        } catch {
            Write-PmcDebug -Level 2 -Category 'UnifiedDataViewer' -Message "Theme initialization failed, using defaults"
        }
    }

    # No column normalization fallbacks — providers must return an array of @{ Name; DisplayName; Width }

    hidden [string] GetColName([object]$col) { if ($null -eq $col) { return '' }; if ($col -is [hashtable]) { return [string]$col['Name'] }; return [string]$col.Name }

    hidden [int] GetColWidth([object]$col) { if ($null -eq $col) { return 0 }; if ($col -is [hashtable]) { return [int]$col['Width'] }; return [int]$col.Width }

    hidden [string] NormalizeDataType([string]$dataType) {
        $normalized = ''
        if (-not $dataType) {
            $normalized = ''
        } else {
            $lower = $dataType.ToLower()
            switch ($lower) {
                'tasks'    { $normalized = 'task' }
                'projects' { $normalized = 'project' }
                default    { $normalized = $lower }
            }
        }
        return $normalized
    }

    # Set the renderer for drawing operations
    [void] SetRenderer([object]$renderer) {
        $this._renderer = $renderer
    }

    hidden [void] EnsureValidBounds() {
        # Ensure _bounds has X,Y,Width,Height; otherwise, default to full buffer
        $hasProps = $false
        try {
            $null = $this._bounds.X; $null = $this._bounds.Y; $null = $this._bounds.Width; $null = $this._bounds.Height
            $hasProps = $true
        } catch { $hasProps = $false }

        if (-not $hasProps) {
            $w = 80; $h = 24
            try {
                if ($this._renderer) {
                    $buf = $this._renderer.GetDrawBuffer()
                    $w = $buf.GetWidth(); $h = $buf.GetHeight()
                } else {
                    $w = [Console]::WindowWidth; $h = [Console]::WindowHeight
                }
            } catch {}
            $this._bounds = [PSCustomObject]@{ X = 0; Y = 0; Width = $w; Height = $h }
            # Debug removed
        }
    }

    # Set data type and refresh
    [void] SetDataType([string]$dataType) {
        if ($this._state.DataType -ne $dataType) {
            $this._state.DataType = $dataType
            $this._state.Reset()
            $this.RefreshData()
        }
    }

    # Execute a query and update display
    [void] ExecuteQuery([string]$query) {
        if (-not $this._initialized) { return }

        $this._state.Query = $query
        Write-PmcDebug -Level 2 -Category 'UnifiedDataViewer' -Message "Executing query: '$query'"

        try {
            if ($this.QueryExecutor) {
                # Use PMC's existing query system
                $result = & $this.QueryExecutor $query
                if ($result) {
                    $this._state.SetData($result)
                    $this.ApplyFilters()
                    $this.Render()

                    if ($this.OnQueryChanged) {
                        & $this.OnQueryChanged $query $result
                    }
                }
            } else {
                Write-PmcDebug -Level 1 -Category 'UnifiedDataViewer' -Message "No query executor configured"
            }
        } catch {
            Write-PmcDebug -Level 1 -Category 'UnifiedDataViewer' -Message "Query execution failed: $_"
        }
    }

    # Refresh data from provider
    [void] RefreshData() {
        if (-not $this._initialized -or -not $this.DataProvider) { return }

        try {
            $newData = & $this.DataProvider $this._state.DataType
            if ($newData -and $this._state.HasDataChanged($newData)) {
                $this._state.SetData($newData)
                $this.ApplyFilters()
                $this.Render()

                if ($this.OnDataChanged) {
                    & $this.OnDataChanged $newData
                }

                Write-PmcDebug -Level 3 -Category 'UnifiedDataViewer' -Message "Data refreshed: $($newData.Count) items"
            }
        } catch {
            Write-PmcDebug -Level 1 -Category 'UnifiedDataViewer' -Message "Data refresh failed: $_"
        }
    }

    # Apply current filters to data
    [void] ApplyFilters() {
        $this._state.FilteredData = $this._state.Data

        # Apply sorting if specified
        if ($this._state.SortColumn -and $this._state.FilteredData.Count -gt 0) {
            try {
                if ($this._state.SortDirection -eq "desc") {
                    $this._state.FilteredData = $this._state.FilteredData | Sort-Object $this._state.SortColumn -Descending
                } else {
                    $this._state.FilteredData = $this._state.FilteredData | Sort-Object $this._state.SortColumn
                }
            } catch {
                Write-PmcDebug -Level 2 -Category 'UnifiedDataViewer' -Message "Sort failed on column $($this._state.SortColumn)"
            }
        }

        # Apply filters
        foreach ($filterKey in $this._state.Filters.Keys) {
            $filterValue = $this._state.Filters[$filterKey]
            try {
                $this._state.FilteredData = $this._state.FilteredData | Where-Object { $_.$filterKey -like "*$filterValue*" }
            } catch {
                Write-PmcDebug -Level 2 -Category 'UnifiedDataViewer' -Message "Filter failed on $filterKey"
            }
        }

        # Ensure selected row is still valid
        if ($this._state.SelectedRow -ge $this._state.FilteredData.Count) {
            $this._state.SelectedRow = [Math]::Max(0, $this._state.FilteredData.Count - 1)
        }
    }

    # Navigation methods
    [void] MoveSelection([int]$delta) {
        $newRow = $this._state.SelectedRow + $delta
        $newRow = [Math]::Max(0, [Math]::Min($newRow, $this._state.FilteredData.Count - 1))

        if ($newRow -ne $this._state.SelectedRow) {
            $this._state.SelectedRow = $newRow
            $this.EnsureRowVisible()
            $buf = $this._renderer.GetDrawBuffer()
            $this.RenderDataRows($buf)

            if ($this.OnSelectionChanged) {
                $selectedItem = if ($this._state.FilteredData.Count -gt $this._state.SelectedRow) {
                    $this._state.FilteredData[$this._state.SelectedRow]
                } else { $null }
                & $this.OnSelectionChanged $this._state.SelectedRow $selectedItem
            }
        }
    }

    [void] EnsureRowVisible() {
        $visibleStart = $this._state.ScrollOffset
        $visibleEnd = $this._state.ScrollOffset + $this._state.VisibleRows - 1

        if ($this._state.SelectedRow -lt $visibleStart) {
            $this._state.ScrollOffset = $this._state.SelectedRow
        } elseif ($this._state.SelectedRow -gt $visibleEnd) {
            $this._state.ScrollOffset = $this._state.SelectedRow - $this._state.VisibleRows + 1
        }

        $this._state.ScrollOffset = [Math]::Max(0, $this._state.ScrollOffset)
    }

    # Rendering methods
    [void] Render() {
        if (-not $this._initialized -or -not $this._renderer) { return }

        $this.EnsureValidBounds()

        $buffer = $this._renderer.GetDrawBuffer()

        # Clear the viewer area
        $buffer.ClearRegion($this._bounds.X, $this._bounds.Y, $this._bounds.Width, $this._bounds.Height)

        # Calculate layout
        $this._state.VisibleRows = $this._bounds.Height - 2  # Leave space for header and border

        $this.RenderHeader($buffer)
        $this.RenderDataRows($buffer)
        $this.RenderStatus($buffer)
    }

    [void] RenderHeader([object]$buffer) {
        $this.EnsureValidBounds()
        # Get column definitions
        $columns = $this.GetColumnDefinitions()
        # Legacy debug removed
        if (-not $columns -or $columns.Count -eq 0) { return }

        $y = $this._bounds.Y
        $x = $this._bounds.X + 1

        # Calculate column widths — no fallbacks
        $availableWidth = $this._bounds.Width - 2
        $columnWidths = $this.CalculateColumnWidths($columns, $availableWidth)

        # Render column headers
        foreach ($column in $columns) {
            $name = $this.GetColName($column)
            if (-not $name) { continue }
            $width = $columnWidths[$name]
            if ($width -le 0) { continue }

            $headerText = $name
            if ($column -is [hashtable]) {
                if ($column.ContainsKey('DisplayName')) { $headerText = [string]$column['DisplayName'] }
            } elseif ($column.PSObject.Properties['DisplayName']) {
                $headerText = [string]$column.DisplayName
            }
            if ($headerText.Length -gt $width) {
                $headerText = $headerText.Substring(0, $width - 1) + "…"
            }

            $buffer.SetText($x, $y, $headerText.PadRight($width), $this._theme.HeaderFg, $this._theme.HeaderBg)
            $x += $width + 1
        }
    }

    [void] RenderDataRows([object]$buffer) {
        $this.EnsureValidBounds()
        if (-not $buffer) { $buffer = $this._renderer.GetDrawBuffer() }

        $columns = $this.GetColumnDefinitions()
        if (-not $columns -or $columns.Count -eq 0) { return }

        $availableWidth = $this._bounds.Width - 2
        # Calculate column widths — no fallbacks
        $columnWidths = $this.CalculateColumnWidths($columns, $availableWidth)

        $startY = $this._bounds.Y + 1
        $visibleEnd = [Math]::Min($this._state.ScrollOffset + $this._state.VisibleRows, $this._state.FilteredData.Count)

        for ($i = $this._state.ScrollOffset; $i -lt $visibleEnd; $i++) {
            $rowY = $startY + ($i - $this._state.ScrollOffset)
            $item = $this._state.FilteredData[$i]
            $isSelected = ($i -eq $this._state.SelectedRow)

            $x = $this._bounds.X + 1

            foreach ($column in $columns) {
                $name = $this.GetColName($column)
                if (-not $name) { continue }
                $width = $columnWidths[$name]
                if ($width -le 0) { continue }

                $value = $this.GetColumnValue($item, @{ Name = $name })
                if ($value.Length -gt $width) {
                    $value = $value.Substring(0, $width - 1) + "…"
                }

                $fg = if ($isSelected) { $this._theme.SelectedFg } else { $this._theme.NormalFg }
                $bg = if ($isSelected) { $this._theme.SelectedBg } else { $this._theme.NormalBg }

                $buffer.SetText($x, $rowY, $value.PadRight($width), $fg, $bg)
                $x += $width + 1
            }
        }
    }

    [void] RenderStatus([object]$buffer) {
        $this.EnsureValidBounds()
        $statusY = $this._bounds.Y + $this._bounds.Height - 1
        $statusText = "$($this._state.FilteredData.Count) items"

        if ($this._state.Query) {
            $statusText += " | Query: $($this._state.Query)"
        }

        $buffer.SetText($this._bounds.X + 1, $statusY, $statusText, $this._theme.BorderFg, $this._theme.NormalBg)
    }

    # Column management
    [object] GetColumnDefinitions() {
        # Strict column provider — no fallbacks
        if (-not $this.ColumnProvider) { throw "No ColumnProvider configured" }
        $dt = $this.NormalizeDataType($this._state.DataType)
        $cols = @(& $this.ColumnProvider $dt)
        if (-not $cols -or $cols.Count -eq 0) { throw "Column provider returned no columns for '$dt'" }
        foreach ($c in $cols) {
            if (-not ($c -is [hashtable] -and $c.ContainsKey('Name') -and $c.ContainsKey('DisplayName') -and $c.ContainsKey('Width'))) {
                throw "Invalid column definition encountered (expect @{ Name; DisplayName; Width })"
            }
        }
        return $cols
    }

    [hashtable] CalculateColumnWidths([object]$columns, [int]$availableWidth) {
        $widths = @{}
        $total = 0
        foreach ($column in $columns) {
            if (-not $column) { throw "Null column encountered" }
            $name = $this.GetColName($column)
            $width = $this.GetColWidth($column)
            if (-not $name -or $width -le 0) { throw "Invalid column spec; each column must define Name and Width > 0" }
            $widths[$name] = [int]$width
            $total += [int]$width
        }
        $totalWithSeparators = $total + ([Math]::Max(0, @($columns).Count - 1))
        if ($totalWithSeparators -gt $availableWidth) { throw "Total column widths ($totalWithSeparators) exceed available width ($availableWidth)" }
        return $widths
    }

    [string] GetColumnValue([object]$item, [hashtable]$column) {
        if (-not $item) { return "" }

        try {
            $value = $null
            if ($column.Name -eq 'ToString') {
                $value = $item.ToString()
            } else {
                $value = $item.($column.Name)
            }

            if ($null -eq $value) { return "" }
            return [string]$value
        } catch {
            return ""
        }
    }

    # Public interface
    [PmcDataViewerState] GetState() { return $this._state }
    [object] GetSelectedItem() {
        if ($this._state.FilteredData.Count -gt $this._state.SelectedRow) {
            return $this._state.FilteredData[$this._state.SelectedRow]
        }
        return $null
    }

    [void] SetBounds([object]$bounds) {
        $this._bounds = $bounds
        $this.EnsureValidBounds()
        $this.Render()
    }

    [void] SetAutoRefresh([bool]$enabled) {
        $this._state.AutoRefresh = $enabled
    }

    [bool] ShouldRefresh() {
        if (-not $this._state.AutoRefresh) { return $false }
        $elapsed = ([datetime]::Now - $this._state.LastUpdate).TotalMilliseconds
        return $elapsed -ge $this._state.RefreshIntervalMs
    }
}

# Global instance
$Script:PmcUnifiedDataViewer = $null

function Initialize-PmcUnifiedDataViewer {
    param([object]$Bounds)

    if ($Script:PmcUnifiedDataViewer) {
        Write-Warning "PMC Unified Data Viewer already initialized"
        return
    }

    $Script:PmcUnifiedDataViewer = [PmcUnifiedDataViewer]::new($Bounds)

    # Set up integration with existing PMC systems (strict)
    $Script:PmcUnifiedDataViewer.QueryExecutor = {
        param([string]$query)
        if (-not (Get-Command Invoke-PmcEnhancedQuery -ErrorAction SilentlyContinue)) { throw "Invoke-PmcEnhancedQuery not found" }
        $res = Invoke-PmcEnhancedQuery -QueryString $query
        if ($res -and $res.Data) { return $res.Data }
        return @()
    }

    $Script:PmcUnifiedDataViewer.DataProvider = {
        param([string]$dataType)
        switch ($dataType) {
            'tasks'    { if (Get-Command Get-PmcTasksData -ErrorAction SilentlyContinue)    { return Get-PmcTasksData } else { throw "Get-PmcTasksData not found" } }
            'projects' { if (Get-Command Get-PmcProjectsData -ErrorAction SilentlyContinue) { return Get-PmcProjectsData } else { throw "Get-PmcProjectsData not found" } }
            'timelog'  { if (Get-Command Get-PmcTimeLogsData -ErrorAction SilentlyContinue) { return Get-PmcTimeLogsData } else { throw "Get-PmcTimeLogsData not found" } }
            'help'     {
                # Build help categories from module help content if available
                try {
                    $var = Get-Variable -Name PmcHelpContent -Scope Script -ErrorAction SilentlyContinue
                    if (-not $var) { $var = Get-Variable -Name PmcHelpContent -Scope Global -ErrorAction SilentlyContinue }
                    $hc = if ($var) { $var.Value } else { $null }
                    if ($hc) {
                        $rows = @()
                        foreach ($k in $hc.Keys) {
                            $cat = $hc[$k]
                            $rows += [pscustomobject]@{
                                Category     = [string]$k
                                CommandCount = @($cat.Items).Count
                                Description  = [string]$cat.Description
                            }
                        }
                        return $rows
                    }
                } catch { }
                return @()
            }
            default    { throw "Unknown dataType '$dataType'" }
        }
    }

    $Script:PmcUnifiedDataViewer.ColumnProvider = {
        param([string]$dataType)
        if (-not (Get-Command Get-PmcDefaultColumns -ErrorAction SilentlyContinue)) { throw "Get-PmcDefaultColumns not found" }
        # Normalize to singular like GetColumnDefinitions does
        $dt = switch ($dataType.ToLower()) { 'tasks' { 'task' } 'projects' { 'project' } default { $dataType.ToLower() } }
        $out = @((Get-PmcDefaultColumns -DataType $dt))
        return $out
    }

    Write-PmcDebug -Level 2 -Category 'UnifiedDataViewer' -Message "Unified data viewer initialized"
}

function Get-PmcUnifiedDataViewer {
    return $Script:PmcUnifiedDataViewer
}

function Reset-PmcUnifiedDataViewer {
    $Script:PmcUnifiedDataViewer = $null
}

Export-ModuleMember -Function Initialize-PmcUnifiedDataViewer, Get-PmcUnifiedDataViewer, Reset-PmcUnifiedDataViewer


# END FILE: ./module/Pmc.Strict/UI/UnifiedDataViewer.ps1


# ================================================================================
# PMC MODULE CONCATENATION COMPLETE
# ================================================================================
# Files included: 72
# Total size: 934.79 KB
# Generated: 2025-09-25 05:28:43
# ================================================================================
