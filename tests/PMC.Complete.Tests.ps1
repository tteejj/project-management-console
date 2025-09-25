# COMPREHENSIVE PMC SYSTEM TESTS
# Tests ALL domains, display systems, config, themes, JSON handling, etc.

Describe "Complete PMC System Verification" {
    BeforeAll {
        $ModulePath = Join-Path $PSScriptRoot "../module/Pmc.Strict/Pmc.Strict.psm1"
        # Import-Module for functions and variables
        Import-Module $ModulePath -Force -ErrorAction SilentlyContinue

        # Additional import for class access - classes require 'using module'
        try {
            $null = [PmcTemplate]::new('test', @{})
            $ClassesAvailable = $true
        } catch {
            $ClassesAvailable = $false
        }

        # Get all files for analysis
        $ModuleRoot = Split-Path $ModulePath -Parent
        $AllPsFiles = Get-ChildItem -Path $ModuleRoot -Filter "*.ps1" -Recurse
        $AllJsonFiles = Get-ChildItem -Path (Split-Path $ModuleRoot -Parent) -Filter "*.json" -Recurse
    }

    Context "All Domain Commands from CommandMap" {
        It "Should have ALL domain functions available" {
            $missingFunctions = @()
            $totalCommands = 0

            if (-not $PmcCommandMap) {
                throw "PmcCommandMap is not loaded"
            }

            foreach ($domain in $PmcCommandMap.Keys) {
                foreach ($action in $PmcCommandMap[$domain].Keys) {
                    $functionName = $PmcCommandMap[$domain][$action]
                    $totalCommands++

                    if (-not (Get-Command $functionName -ErrorAction SilentlyContinue)) {
                        $missingFunctions += @{
                            Domain = $domain
                            Action = $action
                            Function = $functionName
                            Command = "$domain $action"
                        }
                    }
                }
            }

            Write-Host "Total commands in CommandMap: $totalCommands" -ForegroundColor Cyan
            if ($missingFunctions.Count -gt 0) {
                Write-Host "MISSING FUNCTIONS:" -ForegroundColor Red
                $missingFunctions | ForEach-Object {
                    Write-Host "  $($_.Domain) $($_.Action) -> $($_.Function)" -ForegroundColor Yellow
                }
            }

            $missingFunctions.Count | Should -Be 0 -Because "All CommandMap functions must exist"
        }
    }

    Context "All Display System Functions" {
        It "Should have core display functions" {
            $displayFunctions = @(
                'Write-PmcStyled',
                'Show-PmcDataWithTemplate',
                'Render-GridTemplate',
                'Render-ListTemplate',
                'Render-CardTemplate',
                'Render-SummaryTemplate'
            )

            $missingDisplay = @()
            foreach ($func in $displayFunctions) {
                if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
                    $missingDisplay += $func
                }
            }

            if ($missingDisplay.Count -gt 0) {
                Write-Host "Missing display functions:" -ForegroundColor Red
                $missingDisplay | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
            }

            $missingDisplay.Count | Should -Be 0 -Because "Display system must be complete"
        }

        It "Should NOT reference non-existent display functions" {
            $badReferences = @()
            $nonExistentFunctions = @('Show-PmcCustomGrid', 'PmcGridRenderer', 'Pmc-InsertAtCursor')

            foreach ($file in $AllPsFiles) {
                $content = Get-Content $file.FullName -Raw
                foreach ($badFunc in $nonExistentFunctions) {
                    if ($content -match $badFunc) {
                        $badReferences += @{
                            File = $file.Name
                            Function = $badFunc
                            Path = $file.FullName
                        }
                    }
                }
            }

            if ($badReferences.Count -gt 0) {
                Write-Host "Files with bad function references:" -ForegroundColor Red
                $badReferences | Group-Object Function | ForEach-Object {
                    Write-Host "  $($_.Name):" -ForegroundColor Yellow
                    $_.Group | ForEach-Object { Write-Host "    $($_.File)" -ForegroundColor Gray }
                }
            }

            $badReferences.Count | Should -Be 0 -Because "No files should reference non-existent functions"
        }
    }

    Context "Task Domain Complete Testing" {
        It "Should have all task functions" {
            $taskFunctions = @(
                'Add-PmcTask', 'Get-PmcTaskList', 'Show-PmcTask', 'Set-PmcTask',
                'Complete-PmcTask', 'Remove-PmcTask', 'Move-PmcTask', 'Set-PmcTaskPostponed',
                'Copy-PmcTask', 'Add-PmcTaskNote', 'Edit-PmcTask', 'Find-PmcTask',
                'Set-PmcTaskPriority', 'Show-PmcAgenda'
            )

            $missingTaskFuncs = @()
            foreach ($func in $taskFunctions) {
                if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
                    $missingTaskFuncs += $func
                }
            }

            if ($missingTaskFuncs.Count -gt 0) {
                Write-Host "Missing task functions:" -ForegroundColor Red
                $missingTaskFuncs | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
            }

            $missingTaskFuncs.Count | Should -Be 0
        }

        It "Should execute task functions without errors" {
            $context = [PSCustomObject]@{ Args = @{}; FreeText = @() }

            # Test functions that should work without parameters
            { Get-PmcTaskList -Context $context } | Should -Not -Throw
        }
    }

    Context "Project Domain Complete Testing" {
        It "Should have all project functions" {
            $projectFunctions = @(
                'Add-PmcProject', 'Get-PmcProjectList', 'Show-PmcProject', 'Set-PmcProject',
                'Edit-PmcProject', 'Rename-PmcProject', 'Remove-PmcProject', 'Set-PmcProjectArchived',
                'Set-PmcProjectFields', 'Show-PmcProjectFields', 'Get-PmcProjectStats',
                'Show-PmcProjectInfo', 'Get-PmcRecentProjects'
            )

            $missingProjFuncs = @()
            foreach ($func in $projectFunctions) {
                if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
                    $missingProjFuncs += $func
                }
            }

            if ($missingProjFuncs.Count -gt 0) {
                Write-Host "Missing project functions:" -ForegroundColor Red
                $missingProjFuncs | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
            }

            $missingProjFuncs.Count | Should -Be 0
        }
    }

    Context "Time Domain Complete Testing" {
        It "Should have all time functions" {
            $timeFunctions = @(
                'Add-PmcTimeEntry', 'Get-PmcTimeReport', 'Get-PmcTimeList',
                'Edit-PmcTimeEntry', 'Remove-PmcTimeEntry'
            )

            $missingTimeFuncs = @()
            foreach ($func in $timeFunctions) {
                if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
                    $missingTimeFuncs += $func
                }
            }

            if ($missingTimeFuncs.Count -gt 0) {
                Write-Host "Missing time functions:" -ForegroundColor Red
                $missingTimeFuncs | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
            }

            $missingTimeFuncs.Count | Should -Be 0
        }
    }

    Context "Timer Domain Complete Testing" {
        It "Should have all timer functions" {
            $timerFunctions = @(
                'Start-PmcTimer', 'Stop-PmcTimer', 'Get-PmcTimerStatus'
            )

            $missingTimerFuncs = @()
            foreach ($func in $timerFunctions) {
                if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
                    $missingTimerFuncs += $func
                }
            }

            if ($missingTimerFuncs.Count -gt 0) {
                Write-Host "Missing timer functions:" -ForegroundColor Red
                $missingTimerFuncs | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
            }

            $missingTimerFuncs.Count | Should -Be 0
        }
    }

    Context "View Domain Complete Testing" {
        It "Should have all view functions" {
            $viewFunctions = @(
                'Show-PmcTodayTasksInteractive', 'Show-PmcTomorrowTasksInteractive',
                'Show-PmcOverdueTasksInteractive', 'Show-PmcUpcomingTasksInteractive',
                'Show-PmcBlockedTasksInteractive', 'Show-PmcTasksWithoutDueDateInteractive',
                'Show-PmcProjectsInteractive', 'Show-PmcNextTasksInteractive',
                'Show-PmcTasksWithoutDueDate', 'Show-PmcKanban'
            )

            $missingViewFuncs = @()
            foreach ($func in $viewFunctions) {
                if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
                    $missingViewFuncs += $func
                }
            }

            if ($missingViewFuncs.Count -gt 0) {
                Write-Host "Missing view functions:" -ForegroundColor Red
                $missingViewFuncs | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
            }

            $missingViewFuncs.Count | Should -Be 0
        }
    }

    Context "Help Domain Complete Testing" {
        It "Should have all help functions" {
            $helpFunctions = @(
                'Show-PmcSmartHelp', 'Show-PmcHelpDomain', 'Show-PmcHelpCommand',
                'Show-PmcHelpQuery', 'Show-PmcHelpGuide', 'Show-PmcHelpExamples',
                'Show-PmcHelpSearch'
            )

            $missingHelpFuncs = @()
            foreach ($func in $helpFunctions) {
                if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
                    $missingHelpFuncs += $func
                }
            }

            if ($missingHelpFuncs.Count -gt 0) {
                Write-Host "Missing help functions:" -ForegroundColor Red
                $missingHelpFuncs | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
            }

            $missingHelpFuncs.Count | Should -Be 0
        }
    }

    Context "Config Domain Complete Testing" {
        It "Should have all config functions" {
            $configFunctions = @(
                'Show-PmcConfig', 'Edit-PmcConfig', 'Set-PmcConfigValue',
                'Reload-PmcConfig', 'Validate-PmcConfig', 'Set-PmcIconMode'
            )

            $missingConfigFuncs = @()
            foreach ($func in $configFunctions) {
                if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
                    $missingConfigFuncs += $func
                }
            }

            if ($missingConfigFuncs.Count -gt 0) {
                Write-Host "Missing config functions:" -ForegroundColor Red
                $missingConfigFuncs | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
            }

            $missingConfigFuncs.Count | Should -Be 0
        }
    }

    Context "Theme Domain Complete Testing" {
        It "Should have all theme functions" {
            $themeFunctions = @(
                'Reset-PmcTheme', 'Edit-PmcTheme', 'Get-PmcThemeList',
                'Apply-PmcTheme', 'Show-PmcThemeInfo', 'Set-PmcTheme'
            )

            $missingThemeFuncs = @()
            foreach ($func in $themeFunctions) {
                if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
                    $missingThemeFuncs += $func
                }
            }

            if ($missingThemeFuncs.Count -gt 0) {
                Write-Host "Missing theme functions:" -ForegroundColor Red
                $missingThemeFuncs | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
            }

            $missingThemeFuncs.Count | Should -Be 0
        }
    }

    Context "Excel Domain Complete Testing" {
        It "Should have all Excel functions" {
            $excelFunctions = @(
                'Import-PmcExcelData', 'Show-PmcExcelPreview', 'Get-PmcLatestExcelFile'
            )

            $missingExcelFuncs = @()
            foreach ($func in $excelFunctions) {
                if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
                    $missingExcelFuncs += $func
                }
            }

            if ($missingExcelFuncs.Count -gt 0) {
                Write-Host "Missing Excel functions:" -ForegroundColor Red
                $missingExcelFuncs | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
            }

            $missingExcelFuncs.Count | Should -Be 0
        }
    }

    Context "Data Storage and JSON Handling" {
        It "Should have data access functions" {
            $dataFunctions = @(
                'Get-PmcData', 'Save-PmcData', 'Get-PmcAllData', 'Set-PmcAllData'
            )

            $missingDataFuncs = @()
            foreach ($func in $dataFunctions) {
                if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
                    $missingDataFuncs += $func
                }
            }

            if ($missingDataFuncs.Count -gt 0) {
                Write-Host "Missing data functions:" -ForegroundColor Red
                $missingDataFuncs | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
            }

            $missingDataFuncs.Count | Should -Be 0
        }

        It "Should validate JSON files exist and are parseable" {
            $jsonErrors = @()

            foreach ($jsonFile in $AllJsonFiles) {
                try {
                    $content = Get-Content $jsonFile.FullName -Raw -ErrorAction Stop
                    if ($content) {
                        $null = ConvertFrom-Json $content -ErrorAction Stop
                    }
                } catch {
                    $jsonErrors += @{
                        File = $jsonFile.Name
                        Error = $_.Exception.Message
                        Path = $jsonFile.FullName
                    }
                }
            }

            if ($jsonErrors.Count -gt 0) {
                Write-Host "JSON file errors:" -ForegroundColor Red
                $jsonErrors | ForEach-Object {
                    Write-Host "  $($_.File): $($_.Error)" -ForegroundColor Yellow
                }
            }

            $jsonErrors.Count | Should -Be 0 -Because "All JSON files should be valid"
        }
    }

    Context "State Management Testing" {
        It "Should have state management functions" {
            $stateFunctions = @(
                'Get-PmcState', 'Set-PmcState'
            )

            $missingStateFuncs = @()
            foreach ($func in $stateFunctions) {
                if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
                    $missingStateFuncs += $func
                }
            }

            if ($missingStateFuncs.Count -gt 0) {
                Write-Host "Missing state functions:" -ForegroundColor Red
                $missingStateFuncs | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
            }

            $missingStateFuncs.Count | Should -Be 0
        }
    }

    Context "Template System Complete Testing" {
        It "Should have PmcTemplate class available" -Skip:(-not $ClassesAvailable) {
            { [PmcTemplate]::new('test', @{}) } | Should -Not -Throw -Because "PmcTemplate class must exist"
        }

        It "Should have all template types working" -Skip:(-not $ClassesAvailable) {
            $template = [PmcTemplate]::new('test', @{
                type = 'grid'
                header = 'Test Header'
                row = '{name} {value}'
            })

            $template.Type | Should -Be 'grid'
            $template.Header | Should -Be 'Test Header'
            $template.Row | Should -Be '{name} {value}'
        }
    }

    Context "All Other Domains Testing" {
        It "Should have dependency functions" {
            $depFunctions = @(
                'Add-PmcDependency', 'Remove-PmcDependency', 'Show-PmcDependencies',
                'Show-PmcDependencyGraph'
            )

            $missingDepFuncs = @()
            foreach ($func in $depFunctions) {
                if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
                    $missingDepFuncs += $func
                }
            }

            if ($missingDepFuncs.Count -gt 0) {
                Write-Host "Missing dependency functions:" -ForegroundColor Red
                $missingDepFuncs | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
            }

            $missingDepFuncs.Count | Should -Be 0
        }

        It "Should have focus management functions" {
            $focusFunctions = @(
                'Set-PmcFocus', 'Clear-PmcFocus', 'Get-PmcFocusStatus'
            )

            $missingFocusFuncs = @()
            foreach ($func in $focusFunctions) {
                if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
                    $missingFocusFuncs += $func
                }
            }

            if ($missingFocusFuncs.Count -gt 0) {
                Write-Host "Missing focus functions:" -ForegroundColor Red
                $missingFocusFuncs | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
            }

            $missingFocusFuncs.Count | Should -Be 0
        }

        It "Should have system functions" {
            $systemFunctions = @(
                'Invoke-PmcUndo', 'Invoke-PmcRedo', 'New-PmcBackup', 'Clear-PmcCompletedTasks'
            )

            $missingSystemFuncs = @()
            foreach ($func in $systemFunctions) {
                if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
                    $missingSystemFuncs += $func
                }
            }

            if ($missingSystemFuncs.Count -gt 0) {
                Write-Host "Missing system functions:" -ForegroundColor Red
                $missingSystemFuncs | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
            }

            $missingSystemFuncs.Count | Should -Be 0
        }
    }

    Context "Shortcut Map Complete Testing" {
        It "Should have ALL shortcut functions available" {
            $missingShortcuts = @()

            if (-not $PmcShortcutMap) {
                throw "PmcShortcutMap is not loaded"
            }

            foreach ($shortcut in $PmcShortcutMap.Keys) {
                $functionName = $PmcShortcutMap[$shortcut]

                if (-not (Get-Command $functionName -ErrorAction SilentlyContinue)) {
                    $missingShortcuts += @{
                        Shortcut = $shortcut
                        Function = $functionName
                    }
                }
            }

            if ($missingShortcuts.Count -gt 0) {
                Write-Host "Missing shortcut functions:" -ForegroundColor Red
                $missingShortcuts | ForEach-Object {
                    Write-Host "  $($_.Shortcut) -> $($_.Function)" -ForegroundColor Yellow
                }
            }

            $missingShortcuts.Count | Should -Be 0 -Because "All shortcuts must have working functions"
        }
    }
}