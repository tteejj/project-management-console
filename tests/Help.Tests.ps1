# Comprehensive tests for Help System functionality

Describe "Help System" {
    BeforeAll {
        $ModulePath = Join-Path $PSScriptRoot "../module/Pmc.Strict/Pmc.Strict.psm1"
        Import-Module $ModulePath -Force
    }

    Context "Help Function Availability" {
        It "Should have all required help functions exported" {
            $helpFunctions = @(
                'Show-PmcSmartHelp',
                'Show-PmcHelpCategories',
                'Show-PmcHelpCommands',
                'Show-PmcHelpDomain',
                'Show-PmcHelpCommand',
                'Show-PmcHelpQuery',
                'Show-PmcHelpExamples',
                'Show-PmcHelpGuide',
                'Show-PmcHelpSearch'
            )

            foreach ($func in $helpFunctions) {
                Get-Command $func -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty -Because "$func should be available"
            }
        }
    }

    Context "Template Display Dependencies" {
        It "Should have access to template rendering functions" {
            $templateFunctions = @(
                'Render-GridTemplate',
                'Render-ListTemplate',
                'Write-PmcStyled'
            )

            foreach ($func in $templateFunctions) {
                Get-Command $func -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty -Because "$func should be available for help display"
            }
        }

        It "Should have PmcTemplate class available" {
            # Try to create a template instance
            { [PmcTemplate]::new('test', @{}) } | Should -Not -Throw
        }
    }

    Context "CommandMap Integration" {
        It "Should have CommandMap variable available" {
            $Script:PmcCommandMap | Should -Not -BeNullOrEmpty
        }

        It "Should have CommandMeta for descriptions" {
            $Script:PmcCommandMeta | Should -Not -BeNullOrEmpty
        }

        It "Should have help domain in CommandMap" {
            $Script:PmcCommandMap.ContainsKey('help') | Should -Be $true
        }
    }

    Context "Help Function Execution" {
        It "Should execute help categories without errors" {
            $context = [PSCustomObject]@{
                Args = @{}
                FreeText = @()
            }

            { Show-PmcHelpCategories -Context $context } | Should -Not -Throw
        }

        It "Should execute help domain with valid domain" {
            $context = [PSCustomObject]@{
                Args = @{ domain = 'task' }
                FreeText = @()
            }

            { Show-PmcHelpDomain -Context $context } | Should -Not -Throw
        }

        It "Should execute help search with query" {
            $context = [PSCustomObject]@{
                Args = @{ query = 'task' }
                FreeText = @()
            }

            { Show-PmcHelpSearch -Context $context } | Should -Not -Throw
        }

        It "Should handle invalid domain gracefully" {
            $context = [PSCustomObject]@{
                Args = @{ domain = 'nonexistent' }
                FreeText = @()
            }

            { Show-PmcHelpDomain -Context $context } | Should -Not -Throw
        }
    }

    Context "Help Content Rendering" {
        It "Should render help topics without errors" {
            $context = [PSCustomObject]@{
                Args = @{}
                FreeText = @()
            }

            { Show-PmcHelpTopic -Context $context -Topic 'query' } | Should -Not -Throw
            { Show-PmcHelpTopic -Context $context -Topic 'examples' } | Should -Not -Throw
        }

        It "Should handle missing help topics gracefully" {
            $context = [PSCustomObject]@{
                Args = @{}
                FreeText = @()
            }

            { Show-PmcHelpTopic -Context $context -Topic 'nonexistent' } | Should -Not -Throw
        }
    }
}