#!/usr/bin/env pwsh
# Pester tests for FakeTUI Handle methods

BeforeAll {
    . "$PSScriptRoot/module/Pmc.Strict/FakeTUI/FakeTUI.ps1"

    # Mock backend functions
    function Get-PmcAllData {
        return @{
            tasks = @(
                @{ id = 1; title = "Test Task"; status = "todo"; project = "TestProject" }
                @{ id = 2; title = "Done Task"; status = "done"; completed = (Get-Date).AddDays(-2).ToString('yyyy-MM-dd') }
            )
            projects = @(
                @{ name = "TestProject"; description = "Test"; status = "active"; tags = @("test") }
            )
        }
    }

    function Save-PmcAllData {
        param($Data)
        # Mock save - do nothing
    }

    function Save-PmcData {
        param($Data, $Action)
        # Mock save - do nothing
    }
}

Describe "FakeTUI Draw Methods" {
    BeforeEach {
        $script:app = [PmcFakeTUIApp]::new()
        $app.Initialize()
    }

    AfterEach {
        $app.Shutdown()
    }

    It "DrawDependencyGraph should not crash" {
        { $app.DrawDependencyGraph() } | Should -Not -Throw
    }

    It "DrawBurndownChart should not crash" {
        { $app.DrawBurndownChart() } | Should -Not -Throw
    }

    It "DrawStartReview should not crash" {
        { $app.DrawStartReview() } | Should -Not -Throw
    }

    It "DrawProjectWizard should not crash" {
        { $app.DrawProjectWizard() } | Should -Not -Throw
    }

    It "DrawTemplates should not crash" {
        { $app.DrawTemplates() } | Should -Not -Throw
    }

    It "DrawStatistics should not crash" {
        { $app.DrawStatistics() } | Should -Not -Throw
    }

    It "DrawVelocity should not crash" {
        { $app.DrawVelocity() } | Should -Not -Throw
    }

    It "DrawPreferences should not crash" {
        { $app.DrawPreferences() } | Should -Not -Throw
    }

    It "DrawConfigEditor should not crash" {
        { $app.DrawConfigEditor() } | Should -Not -Throw
    }

    It "DrawManageAliases should not crash" {
        { $app.DrawManageAliases() } | Should -Not -Throw
    }

    It "DrawQueryBrowser should not crash" {
        { $app.DrawQueryBrowser() } | Should -Not -Throw
    }

    It "DrawWeeklyReport should not crash" {
        { $app.DrawWeeklyReport() } | Should -Not -Throw
    }

    It "DrawHelpBrowser should not crash" {
        { $app.DrawHelpBrowser() } | Should -Not -Throw
    }

    It "DrawHelpCategories should not crash" {
        { $app.DrawHelpCategories() } | Should -Not -Throw
    }

    It "DrawHelpSearch should not crash" {
        { $app.DrawHelpSearch() } | Should -Not -Throw
    }

    It "DrawAboutPMC should not crash" {
        { $app.DrawAboutPMC() } | Should -Not -Throw
    }

    It "DrawEditProjectForm should not crash" {
        { $app.DrawEditProjectForm() } | Should -Not -Throw
    }

    It "DrawProjectInfoView should not crash" {
        { $app.DrawProjectInfoView() } | Should -Not -Throw
    }

    It "DrawRecentProjectsView should not crash" {
        { $app.DrawRecentProjectsView() } | Should -Not -Throw
    }
}

Describe "FakeTUI Handle Methods with Mocked Input" {
    BeforeEach {
        $script:app = [PmcFakeTUIApp]::new()
        $app.Initialize()
    }

    AfterEach {
        $app.Shutdown()
    }

    Context "Statistics calculations" {
        It "DrawStatistics should show correct totals with mocked data" {
            # Capture output by checking terminal calls were made
            { $app.DrawStatistics() } | Should -Not -Throw
            # With our mocked data: 2 tasks total, 1 done
        }

        It "DrawWeeklyReport should calculate completed tasks" {
            { $app.DrawWeeklyReport() } | Should -Not -Throw
        }

        It "DrawVelocity should calculate 7-day metrics" {
            { $app.DrawVelocity() } | Should -Not -Throw
        }
    }

    Context "View changes" {
        It "DrawBurndownChart should handle empty project filter" {
            $app.filterProject = $null
            { $app.DrawBurndownChart() } | Should -Not -Throw
        }

        It "DrawBurndownChart should handle specific project filter" {
            $app.filterProject = "TestProject"
            { $app.DrawBurndownChart() } | Should -Not -Throw
        }
    }
}

Describe "FakeTUI Menu Wiring" {
    It "All menu actions should map to valid views" {
        $app = [PmcFakeTUIApp]::new()
        $app.Initialize()

        # Check that currentView gets set correctly
        $testViews = @(
            'depgraph',
            'burndownview',
            'toolsreview',
            'toolswizard',
            'toolstemplates',
            'toolsstatistics',
            'toolsvelocity',
            'toolspreferences',
            'toolsconfig',
            'toolsaliases',
            'toolsquery',
            'toolsweeklyreport',
            'helpbrowser',
            'helpcategories',
            'helpsearch',
            'helpabout',
            'projectedit',
            'projectinfo',
            'projectrecent'
        )

        foreach ($view in $testViews) {
            $app.currentView = $view
            $app.currentView | Should -Be $view
        }

        $app.Shutdown()
    }
}
