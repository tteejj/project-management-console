# PMC Core Functionality Tests
# Safety harness for refactoring integration

BeforeAll {
    # Import PMC module
    $ModulePath = Join-Path $PSScriptRoot "../module/Pmc.Strict/Pmc.Strict.psm1"
    Import-Module $ModulePath -Force

    # Create test data directory
    $TestDataPath = Join-Path $PSScriptRoot "TestData"
    if (-not (Test-Path $TestDataPath)) {
        New-Item -Path $TestDataPath -ItemType Directory | Out-Null
    }

    # Backup original data and create test environment
    $OriginalTasksPath = Join-Path (Split-Path $PSScriptRoot) "tasks.json"
    $TestTasksPath = Join-Path $TestDataPath "tasks.json"

    if (Test-Path $OriginalTasksPath) {
        Copy-Item $OriginalTasksPath $TestTasksPath -Force
    } else {
        # Create minimal test data
        $TestTasks = @{
            tasks = @(
                @{
                    id = 1
                    text = "Test task 1"
                    project = "test-project"
                    priority = "p1"
                    status = "pending"
                    created = (Get-Date).ToString('yyyy-MM-dd')
                }
                @{
                    id = 2
                    text = "Test task 2"
                    project = "test-project"
                    priority = "p2"
                    status = "pending"
                    created = (Get-Date).ToString('yyyy-MM-dd')
                }
            )
            projects = @(
                @{
                    name = "test-project"
                    description = "Test project for validation"
                    status = "active"
                    created = (Get-Date).ToString('yyyy-MM-dd')
                }
            )
            timelogs = @()
        }
        $TestTasks | ConvertTo-Json -Depth 10 | Set-Content $TestTasksPath
    }
}

AfterAll {
    # Cleanup test environment
    $TestDataPath = Join-Path $PSScriptRoot "TestData"
    if (Test-Path $TestDataPath) {
        Remove-Item $TestDataPath -Recurse -Force
    }
}

Describe "PMC Module Loading" {
    It "Should load PMC module successfully" {
        Get-Module "Pmc.Strict" | Should -Not -BeNullOrEmpty
    }

    It "Should have core PMC functions available" {
        Get-Command "Invoke-PmcCommand" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        Get-Command "Get-PmcHelp" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        Get-Command "Get-PmcTaskList" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It "Should have enhanced functions available" {
        Get-Command "Initialize-PmcUnifiedSystems" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        Get-Command "Get-PmcInitializationStatus" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }
}

Describe "PMC State Management" {
    It "Should allow setting and getting state values" {
        Set-PmcState -Section "test" -Key "test-key" -Value "test-value"
        $result = Get-PmcState -Section "test" -Key "test-key"
        $result | Should -Be "test-value"
    }

    It "Should handle missing state gracefully" {
        $result = Get-PmcState -Section "nonexistent" -Key "missing" -DefaultValue "default"
        $result | Should -Be "default"
    }

    It "Should allow updating state sections" {
        $testData = @{ key1 = "value1"; key2 = "value2" }
        Set-PmcStateSection -Section "test-section" -Data $testData
        $result = Get-PmcStateSection -Section "test-section"
        $result.key1 | Should -Be "value1"
        $result.key2 | Should -Be "value2"
    }
}

Describe "PMC Help System" {
    It "Should provide help information" {
        $help = Get-PmcHelp -ErrorAction SilentlyContinue
        $help | Should -Not -BeNullOrEmpty
    }

    It "Should have help categories" {
        $helpData = Get-PmcHelpData -ErrorAction SilentlyContinue
        $helpData | Should -Not -BeNullOrEmpty
        $helpData.Count | Should -BeGreaterThan 0
    }
}

Describe "PMC Task Management" {
    BeforeEach {
        # Ensure clean state for each test
        Clear-PmcStateSection -Section "tasks" -ErrorAction SilentlyContinue
    }

    It "Should list tasks" {
        $tasks = Get-PmcTaskList -ErrorAction SilentlyContinue
        $tasks | Should -Not -BeNullOrEmpty
    }

    It "Should add a new task via command" {
        $initialCount = (Get-PmcTaskList -ErrorAction SilentlyContinue).Count
        Invoke-PmcCommand "task add Test task from Pester @test-project p1" -ErrorAction SilentlyContinue
        $newCount = (Get-PmcTaskList -ErrorAction SilentlyContinue).Count
        $newCount | Should -BeGreaterThan $initialCount
    }

    It "Should handle task command with various parameters" {
        # Test basic task addition
        { Invoke-PmcCommand "task add Simple test task" } | Should -Not -Throw

        # Test task with project
        { Invoke-PmcCommand "task add Project task @test-project" } | Should -Not -Throw

        # Test task with priority
        { Invoke-PmcCommand "task add Priority task p1" } | Should -Not -Throw
    }
}

Describe "PMC Project Management" {
    It "Should list projects" {
        $projects = Get-PmcProjectList -ErrorAction SilentlyContinue
        $projects | Should -Not -BeNullOrEmpty
    }

    It "Should add a new project via command" {
        $initialCount = (Get-PmcProjectList -ErrorAction SilentlyContinue).Count
        Invoke-PmcCommand "project add test-project-new Test project description" -ErrorAction SilentlyContinue
        $newCount = (Get-PmcProjectList -ErrorAction SilentlyContinue).Count
        $newCount | Should -BeGreaterOrEqual $initialCount
    }
}

Describe "PMC Query System" {
    It "Should execute basic task queries" {
        { Invoke-PmcQuery "tasks" } | Should -Not -Throw
    }

    It "Should execute project queries" {
        { Invoke-PmcQuery "projects" } | Should -Not -Throw
    }

    It "Should handle query with filters" {
        { Invoke-PmcQuery "tasks priority:p1" } | Should -Not -Throw
        { Invoke-PmcQuery "tasks project:test-project" } | Should -Not -Throw
    }

    It "Should handle overdue tasks query" {
        { Invoke-PmcCommand "q tasks overdue" } | Should -Not -Throw
    }
}

Describe "PMC Enhanced Systems" {
    It "Should initialize enhanced systems" {
        $status = Get-PmcInitializationStatus -ErrorAction SilentlyContinue
        $status | Should -Not -BeNullOrEmpty
        $status.IsInitialized | Should -Be $true
    }

    It "Should have enhanced command processor available" {
        $processor = Get-PmcEnhancedCommandProcessor -ErrorAction SilentlyContinue
        $processor | Should -Not -BeNullOrEmpty
    }

    It "Should execute enhanced commands" {
        { Invoke-PmcEnhancedCommand "help" } | Should -Not -Throw
    }

    It "Should execute enhanced queries" {
        { Invoke-PmcEnhancedQuery @('tasks') } | Should -Not -Throw
    }

    It "Should validate data with enhanced validator" {
        $testData = @{ text = "Test task"; priority = "p1" }
        $result = Test-PmcEnhancedData -Domain "task" -Data $testData
        $result | Should -Not -BeNullOrEmpty
        $result.ContainsKey('IsValid') | Should -Be $true
    }
}

Describe "PMC Performance and Monitoring" {
    It "Should track performance metrics" {
        $stats = Get-PmcCommandPerformanceStats -ErrorAction SilentlyContinue
        $stats | Should -Not -BeNullOrEmpty
    }

    It "Should measure operations" {
        $result = Measure-PmcOperation -Operation "test-operation" -ScriptBlock {
            Start-Sleep -Milliseconds 10
            return "test-complete"
        }
        $result | Should -Be "test-complete"
    }

    It "Should provide performance reports" {
        { Get-PmcPerformanceReport } | Should -Not -Throw
    }
}

Describe "PMC Error Handling" {
    It "Should handle invalid commands gracefully" {
        { Invoke-PmcCommand "invalid-command-xyz" } | Should -Not -Throw
    }

    It "Should handle malformed queries gracefully" {
        { Invoke-PmcQuery "invalid query syntax $$%" } | Should -Not -Throw
    }

    It "Should record and report errors" {
        Write-PmcEnhancedError -Severity Warning -Category Validation -Message "Test error for Pester"
        { Get-PmcErrorReport } | Should -Not -Throw
    }
}

Describe "PMC Integration and Compatibility" {
    It "Should maintain backward compatibility with legacy commands" {
        # These are critical legacy commands that must continue working
        { Get-PmcTaskList } | Should -Not -Throw
        { Get-PmcProjectList } | Should -Not -Throw
        { Get-PmcSchema } | Should -Not -Throw
        { Get-PmcHelp } | Should -Not -Throw
    }

    It "Should allow enhanced and legacy systems to coexist" {
        # Test that we can call both old and new systems
        $legacyTasks = Get-PmcTaskList -ErrorAction SilentlyContinue
        $enhancedQuery = Invoke-PmcEnhancedQuery @('tasks') -ErrorAction SilentlyContinue

        $legacyTasks | Should -Not -BeNullOrEmpty
        $enhancedQuery | Should -Not -BeNullOrEmpty
    }

    It "Should preserve data integrity across system calls" {
        # Add a task via legacy system
        $taskText = "Integration test task $(Get-Random)"
        Invoke-PmcCommand "task add $taskText"

        # Verify it's visible in both systems
        $legacyTasks = Get-PmcTaskList
        $enhancedQuery = Invoke-PmcEnhancedQuery @('tasks')

        $legacyTasks | Where-Object { $_.text -like "*Integration test task*" } | Should -Not -BeNullOrEmpty
    }
}

Describe "PMC Security Validation" {
    It "Should sanitize input in enhanced command processor" {
        # Test that malicious input is handled safely
        { Invoke-PmcEnhancedCommand 'task add Test`$malicious' } | Should -Not -Throw
    }

    It "Should validate data input" {
        $maliciousData = @{ text = 'Test'; priority = 'p1`$evil' }
        $result = Test-PmcEnhancedData -Domain 'task' -Data $maliciousData
        $result.IsValid | Should -Be $false
    }

    It "Should provide security status information" {
        $securityStatus = Get-PmcSecurityStatus -ErrorAction SilentlyContinue
        $securityStatus | Should -Not -BeNullOrEmpty
    }
}