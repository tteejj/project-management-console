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
        'Show-PmcHelpUI',
        'Show-PmcHelpDomain',
        'Show-PmcHelpCommand',
        'Show-PmcHelpAll',
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
        'Get-PmcRecurringList',
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
        # DATA DISPLAY SYSTEM
        'Show-PmcDataGrid',
        # UNIVERSAL DISPLAY SYSTEM
        'Show-PmcData',
        'Get-PmcDefaultColumns',
        'Register-PmcUniversalCommands',
        'Get-PmcUniversalCommands',
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
        'Show-PmcCustomGrid'
    )
    AliasesToExport   = @()
    CmdletsToExport   = @()
    VariablesToExport = @()
}
