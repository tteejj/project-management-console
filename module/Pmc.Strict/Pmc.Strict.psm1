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

# Initialize help content data structure
$Script:PmcHelpContent = @{
    "Query & Search" = @{
        Description = "Query language, filters, and search"
        Items = @(
            @{ Type = "🎯 PRIORITY"; Command = "q tasks p1"; Description = "High priority only (p1/p2/p3)" }
            @{ Type = "🎯 PRIORITY"; Command = "q tasks p<=2"; Description = "High/medium priority" }
            @{ Type = "🎯 PRIORITY"; Command = "q tasks p>=2"; Description = "Medium/low priority" }
            @{ Type = "📅 DATE"; Command = "q tasks due:today"; Description = "Due today" }
            @{ Type = "📅 DATE"; Command = "q tasks due>today"; Description = "Due in future" }
            @{ Type = "📅 DATE"; Command = "q tasks overdue"; Description = "Past due" }
            @{ Type = "📅 DATE"; Command = "q tasks due<=7d"; Description = "Due within 7 days" }
            @{ Type = "📅 DATE"; Command = "q tasks due:2024-12-25"; Description = "Due on specific date" }
            @{ Type = "🏷️ PROJECT"; Command = "q tasks @work"; Description = "Work project tasks" }
            @{ Type = "🏷️ PROJECT"; Command = "q tasks #urgent"; Description = "Tagged urgent" }
            @{ Type = "🏷️ PROJECT"; Command = "q tasks @work #urgent"; Description = "Work project, urgent tag" }
            @{ Type = "🔗 ADVANCED"; Command = "q tasks p<=2 @work due>=today"; Description = "Multiple filters combined" }
            @{ Type = "🔗 ADVANCED"; Command = "q tasks cols:id,text,due"; Description = "Select specific columns" }
            @{ Type = "🔗 ADVANCED"; Command = "q tasks sort:due"; Description = "Sort by due date" }
            @{ Type = "🔗 ADVANCED"; Command = "q tasks view:kanban"; Description = "Force kanban view" }
            @{ Type = "🔗 ADVANCED"; Command = "q tasks group:status"; Description = "Group by status field" }
        )
    }
    "Views & Filters" = @{
        Description = "Display modes and visual layouts"
        Items = @(
            @{ Type = "📋 VIEWS"; Command = "agenda"; Description = "Calendar view of tasks" }
            @{ Type = "📋 VIEWS"; Command = "today"; Description = "Today's tasks" }
            @{ Type = "📋 VIEWS"; Command = "overdue"; Description = "Past due tasks" }
            @{ Type = "📋 VIEWS"; Command = "upcoming"; Description = "Future tasks" }
            @{ Type = "📋 VIEWS"; Command = "tasks"; Description = "All pending tasks" }
            @{ Type = "📋 VIEWS"; Command = "projects"; Description = "Projects dashboard" }
            @{ Type = "🎯 KANBAN"; Command = "q tasks group:status"; Description = "Auto-kanban by status" }
            @{ Type = "🎯 KANBAN"; Command = "q tasks group:priority"; Description = "Kanban by priority" }
            @{ Type = "🎯 KANBAN"; Command = "q tasks group:project"; Description = "Kanban by project" }
            @{ Type = "🎯 KANBAN"; Command = "q tasks view:kanban"; Description = "Force kanban view" }
            @{ Type = "⌨️ NAVIGATION"; Command = "↑ ↓ ← →"; Description = "Navigate kanban lanes and cards" }
            @{ Type = "⌨️ NAVIGATION"; Command = "Space"; Description = "Move cards between lanes" }
            @{ Type = "⌨️ NAVIGATION"; Command = "Enter"; Description = "Edit selected task/card" }
            @{ Type = "⌨️ NAVIGATION"; Command = "Escape"; Description = "Exit kanban mode" }
        )
    }
    "Task Management" = @{
        Description = "Creating, editing, and organizing tasks"
        Items = @(
            @{ Type = "➕ CREATE"; Command = "task add 'New task'"; Description = "Add basic task" }
            @{ Type = "➕ CREATE"; Command = "task add 'Meeting' @work p1 due:today"; Description = "Add task with project, priority, due date" }
            @{ Type = "➕ CREATE"; Command = "task add 'Fix bug #123' #urgent"; Description = "Add task with tags" }
            @{ Type = "✅ COMPLETE"; Command = "task done 5"; Description = "Mark task #5 complete" }
            @{ Type = "✅ COMPLETE"; Command = "task done @work"; Description = "Complete all work tasks" }
            @{ Type = "📝 EDIT"; Command = "task update 5 due:2024-12-25"; Description = "Set due date" }
            @{ Type = "📝 EDIT"; Command = "task update 5 p2"; Description = "Change priority" }
            @{ Type = "📝 EDIT"; Command = "task update 5 'Updated text'"; Description = "Change task text" }
            @{ Type = "🔧 ADVANCED"; Command = "task edit 5"; Description = "Interactive task editor" }
            @{ Type = "🔧 ADVANCED"; Command = "task move 5 @newproject"; Description = "Move to different project" }
            @{ Type = "🔧 ADVANCED"; Command = "task delete 5"; Description = "Delete task (careful!)" }
        )
    }
    "Project Management" = @{
        Description = "Project creation and organization"
        Items = @(
            @{ Type = "🆕 CREATE"; Command = "project add 'New Project'"; Description = "Create new project" }
            @{ Type = "🆕 CREATE"; Command = "project add 'Work' -description 'Work tasks'"; Description = "Create project with description" }
            @{ Type = "📋 MANAGE"; Command = "project list"; Description = "Show all projects" }
            @{ Type = "📋 MANAGE"; Command = "project show @work"; Description = "Show project details" }
            @{ Type = "📋 MANAGE"; Command = "project stats"; Description = "Project statistics" }
            @{ Type = "🗂️ ORGANIZE"; Command = "project archive 'Old Project'"; Description = "Archive completed project" }
            @{ Type = "🗂️ ORGANIZE"; Command = "project rename 'Old' 'New Name'"; Description = "Rename project" }
            @{ Type = "🗂️ ORGANIZE"; Command = "project delete 'Unwanted'"; Description = "Delete project (careful!)" }
        )
    }
    "Configuration" = @{
        Description = "Settings and customization"
        Items = @(
            @{ Type = "⚙️ SETTINGS"; Command = "config show"; Description = "View current settings" }
            @{ Type = "⚙️ SETTINGS"; Command = "config set key value"; Description = "Set configuration value" }
            @{ Type = "⚙️ SETTINGS"; Command = "config reset"; Description = "Reset to defaults" }
            @{ Type = "🎨 THEMES"; Command = "theme set blue"; Description = "Change color theme" }
            @{ Type = "🎨 THEMES"; Command = "theme list"; Description = "Show available themes" }
            @{ Type = "🎨 THEMES"; Command = "theme preview"; Description = "Preview themes" }
            @{ Type = "📊 STATUS"; Command = "status"; Description = "System status" }
            @{ Type = "📊 STATUS"; Command = "stats"; Description = "Usage statistics" }
            @{ Type = "📊 STATUS"; Command = "version"; Description = "Version information" }
            @{ Type = "🔧 MAINTENANCE"; Command = "backup"; Description = "Backup data" }
            @{ Type = "🔧 MAINTENANCE"; Command = "import tasks.json"; Description = "Import data" }
            @{ Type = "🔧 MAINTENANCE"; Command = "export backup.json"; Description = "Export data" }
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

# ProjectWizard.ps1 removed - functionality replaced by enhanced Add-PmcProject

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
    Invoke-PmcTaskEditor, `
    Show-PmcAgenda, `
    Show-PmcTodayTasks, `
    Show-PmcOverdueTasks, `
    Show-PmcUpcomingTasks, `
    Show-PmcBlockedTasks, `
    Show-PmcTasksWithoutDueDate, `
    Show-PmcProjectsView, `
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
# ComputedFields.ps1, QueryEvaluator.ps1, KanbanRenderer.ps1 were loaded earlier
