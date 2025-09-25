# Tests to verify all function calls have corresponding definitions

Describe "Missing Functions Verification" {
    BeforeAll {
        $ModulePath = Join-Path $PSScriptRoot "../module/Pmc.Strict/Pmc.Strict.psm1"
        Import-Module $ModulePath -Force

        # Get all PowerShell files in the module
        $ModuleRoot = Split-Path $ModulePath -Parent
        $AllPsFiles = Get-ChildItem -Path $ModuleRoot -Filter "*.ps1" -Recurse
    }

    Context "CommandMap Function References" {
        It "Should have all CommandMap functions available" {
            $missingFunctions = @()

            foreach ($domain in $Script:PmcCommandMap.Keys) {
                foreach ($action in $Script:PmcCommandMap[$domain].Keys) {
                    $functionName = $Script:PmcCommandMap[$domain][$action]

                    if (-not (Get-Command $functionName -ErrorAction SilentlyContinue)) {
                        $missingFunctions += "$domain $action -> $functionName"
                    }
                }
            }

            if ($missingFunctions.Count -gt 0) {
                Write-Host "Missing functions from CommandMap:" -ForegroundColor Red
                $missingFunctions | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
            }

            $missingFunctions.Count | Should -Be 0 -Because "All CommandMap functions should be available"
        }
    }

    Context "Shortcut Map Function References" {
        It "Should have all shortcut functions available" {
            $missingShortcuts = @()

            foreach ($shortcut in $Script:PmcShortcutMap.Keys) {
                $functionName = $Script:PmcShortcutMap[$shortcut]

                if (-not (Get-Command $functionName -ErrorAction SilentlyContinue)) {
                    $missingShortcuts += "$shortcut -> $functionName"
                }
            }

            if ($missingShortcuts.Count -gt 0) {
                Write-Host "Missing functions from ShortcutMap:" -ForegroundColor Red
                $missingShortcuts | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
            }

            $missingShortcuts.Count | Should -Be 0 -Because "All shortcut functions should be available"
        }
    }

    Context "Function Call Analysis" {
        It "Should not have calls to non-existent Show-PmcCustomGrid" {
            $badCalls = @()

            foreach ($file in $AllPsFiles) {
                $content = Get-Content $file.FullName -Raw
                if ($content -match 'Show-PmcCustomGrid') {
                    $badCalls += $file.FullName
                }
            }

            if ($badCalls.Count -gt 0) {
                Write-Host "Files calling non-existent Show-PmcCustomGrid:" -ForegroundColor Red
                $badCalls | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
            }

            $badCalls.Count | Should -Be 0 -Because "Show-PmcCustomGrid does not exist"
        }

        It "Should not have calls to non-existent PmcGridRenderer" {
            $badCalls = @()

            foreach ($file in $AllPsFiles) {
                $content = Get-Content $file.FullName -Raw
                if ($content -match 'PmcGridRenderer') {
                    $badCalls += $file.FullName
                }
            }

            if ($badCalls.Count -gt 0) {
                Write-Host "Files referencing non-existent PmcGridRenderer:" -ForegroundColor Red
                $badCalls | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
            }

            $badCalls.Count | Should -Be 0 -Because "PmcGridRenderer class does not exist"
        }

        It "Should not have calls to non-existent Pmc-InsertAtCursor" {
            $badCalls = @()

            foreach ($file in $AllPsFiles) {
                $content = Get-Content $file.FullName -Raw
                if ($content -match 'Pmc-InsertAtCursor') {
                    $badCalls += $file.FullName
                }
            }

            if ($badCalls.Count -gt 0) {
                Write-Host "Files calling non-existent Pmc-InsertAtCursor:" -ForegroundColor Red
                $badCalls | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
            }

            $badCalls.Count | Should -Be 0 -Because "Pmc-InsertAtCursor function does not exist"
        }
    }

    Context "Recently Fixed Functions" {
        It "Should have Set-PmcAllData function available" {
            Get-Command "Set-PmcAllData" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "Should have Show-PmcTasksWithoutDueDate function available" {
            Get-Command "Show-PmcTasksWithoutDueDate" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "Should have Show-PmcKanban function available" {
            Get-Command "Show-PmcKanban" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "Should NOT have obsolete functions" {
            $obsoleteFunctions = @(
                'Bind-PmcExcelImports',
                'Get-PmcRecurringList',
                'Show-Pmc'
            )

            foreach ($func in $obsoleteFunctions) {
                $command = Get-Command $func -ErrorAction SilentlyContinue
                $command | Should -BeNullOrEmpty -Because "$func should have been removed as obsolete"
            }
        }
    }
}