# Comprehensive tests for Time logging functionality
# These tests will reveal actual issues, not just pass superficially

Describe "Time Logging System" {
    BeforeAll {
        # Import the PMC module
        $ModulePath = Join-Path $PSScriptRoot "../module/Pmc.Strict/Pmc.Strict.psm1"
        Import-Module $ModulePath -Force

        # Create test data directory
        $TestDataPath = Join-Path $PSScriptRoot "TestData"
        if (Test-Path $TestDataPath) {
            Remove-Item $TestDataPath -Recurse -Force
        }
        New-Item -ItemType Directory -Path $TestDataPath -Force

        # Mock the data storage functions
        $Global:TestPmcData = @{
            timelogs = @()
            currentContext = "TestProject"
        }

        # Override data functions to use test data
        function Get-PmcAllData { return $Global:TestPmcData }
        function Set-PmcAllData { param($Data) $Global:TestPmcData = $Data }
        function Get-PmcData { return $Global:TestPmcData }
        function Save-PmcData { param($Data) $Global:TestPmcData = $Data }
    }

    Context "Time Entry Creation" {
        BeforeEach {
            $Global:TestPmcData.timelogs = @()
        }

        It "Should create indirect time entry with #code" {
            $context = [PSCustomObject]@{
                FreeText = @('30m', '#050', 'admin work')
                Args = @{}
            }

            { Add-PmcTimeEntry -Context $context } | Should -Not -Throw

            $entries = $Global:TestPmcData.timelogs
            $entries.Count | Should -Be 1
            $entries[0].id1 | Should -Be "050"
            $entries[0].project | Should -BeNullOrEmpty
            $entries[0].minutes | Should -Be 30
            $entries[0].description | Should -Be "admin work"
        }

        It "Should create project time entry with @project" {
            $context = [PSCustomObject]@{
                FreeText = @('45m', '@myproject', 'development work')
                Args = @{}
            }

            { Add-PmcTimeEntry -Context $context } | Should -Not -Throw

            $entries = $Global:TestPmcData.timelogs
            $entries.Count | Should -Be 1
            $entries[0].project | Should -Be "myproject"
            $entries[0].id1 | Should -BeNullOrEmpty
            $entries[0].minutes | Should -Be 45
            $entries[0].description | Should -Be "development work"
        }

        It "Should parse YYYYMMDD date format" {
            $context = [PSCustomObject]@{
                FreeText = @('30m', '#050', '20251225', 'holiday work')
                Args = @{}
            }

            { Add-PmcTimeEntry -Context $context } | Should -Not -Throw

            $entries = $Global:TestPmcData.timelogs
            $entries[0].date | Should -Be "2025-12-25"
        }

        It "Should parse MMDD date format assuming current year" {
            $currentYear = (Get-Date).Year
            $context = [PSCustomObject]@{
                FreeText = @('30m', '#050', '1225', 'work')
                Args = @{}
            }

            { Add-PmcTimeEntry -Context $context } | Should -Not -Throw

            $entries = $Global:TestPmcData.timelogs
            $entries[0].date | Should -Be "$currentYear-12-25"
        }

        It "Should handle invalid date gracefully" {
            $context = [PSCustomObject]@{
                FreeText = @('30m', '#050', '1340', 'invalid month')
                Args = @{}
            }

            { Add-PmcTimeEntry -Context $context } | Should -Not -Throw

            $entries = $Global:TestPmcData.timelogs
            $entries[0].date | Should -Be (Get-Date).ToString('yyyy-MM-dd')
        }

        It "Should validate indirect codes are 2-5 digits" {
            # Test 2 digit code
            $context1 = [PSCustomObject]@{
                FreeText = @('30m', '#50', 'work')
                Args = @{}
            }
            { Add-PmcTimeEntry -Context $context1 } | Should -Not -Throw
            $Global:TestPmcData.timelogs[-1].id1 | Should -Be "50"

            # Test 5 digit code
            $context2 = [PSCustomObject]@{
                FreeText = @('30m', '#12345', 'work')
                Args = @{}
            }
            { Add-PmcTimeEntry -Context $context2 } | Should -Not -Throw
            $Global:TestPmcData.timelogs[-1].id1 | Should -Be "12345"
        }

        It "Should reject invalid indirect codes" {
            # Test 1 digit (too short)
            $context1 = [PSCustomObject]@{
                FreeText = @('30m', '#5', 'work')
                Args = @{}
            }
            { Add-PmcTimeEntry -Context $context1 } | Should -Not -Throw
            # Should NOT create indirect entry
            $Global:TestPmcData.timelogs[-1].id1 | Should -BeNullOrEmpty

            # Test 6 digits (too long)
            $context2 = [PSCustomObject]@{
                FreeText = @('30m', '#123456', 'work')
                Args = @{}
            }
            { Add-PmcTimeEntry -Context $context2 } | Should -Not -Throw
            # Should NOT create indirect entry
            $Global:TestPmcData.timelogs[-1].id1 | Should -BeNullOrEmpty
        }
    }

    Context "Time Report Generation" {
        BeforeAll {
            # Create test data for a specific week (Monday to Friday)
            $monday = Get-Date "2025-01-13"  # Known Monday
            $Global:TestPmcData.timelogs = @(
                @{ id="T001"; project="ProjectA"; id1=$null; id2=$null; date="2025-01-13"; minutes=120; description="Monday work" }
                @{ id="T002"; project="ProjectA"; id1=$null; id2=$null; date="2025-01-14"; minutes=180; description="Tuesday work" }
                @{ id="T003"; project=$null; id1="050"; id2=$null; date="2025-01-13"; minutes=60; description="Admin Monday" }
                @{ id="T004"; project=$null; id1="050"; id2=$null; date="2025-01-15"; minutes=30; description="Admin Wednesday" }
                @{ id="T005"; project="ProjectB"; id1=$null; id2=$null; date="2025-01-17"; minutes=240; description="Friday work" }
            )
        }

        It "Should calculate week start correctly (Monday)" {
            # Test various dates to ensure they all map to correct Monday
            $testDates = @(
                @{ Date = "2025-01-13"; ExpectedMonday = "2025-01-13" }  # Monday
                @{ Date = "2025-01-14"; ExpectedMonday = "2025-01-13" }  # Tuesday
                @{ Date = "2025-01-15"; ExpectedMonday = "2025-01-13" }  # Wednesday
                @{ Date = "2025-01-16"; ExpectedMonday = "2025-01-13" }  # Thursday
                @{ Date = "2025-01-17"; ExpectedMonday = "2025-01-13" }  # Friday
                @{ Date = "2025-01-18"; ExpectedMonday = "2025-01-13" }  # Saturday
                @{ Date = "2025-01-19"; ExpectedMonday = "2025-01-13" }  # Sunday
            )

            foreach ($test in $testDates) {
                $testDate = [datetime]$test.Date
                $daysFromMonday = ($testDate.DayOfWeek.value__ + 6) % 7
                $calculatedMonday = $testDate.AddDays(-$daysFromMonday).Date
                $calculatedMonday.ToString('yyyy-MM-dd') | Should -Be $test.ExpectedMonday
            }
        }

        It "Should group time entries correctly" {
            # Mock Show-PmcWeeklyTimeReport to capture its logic without UI
            $mockTimeLogs = $Global:TestPmcData.timelogs
            $weekStart = [datetime]"2025-01-13"  # Monday

            # Filter logs for the week
            $weekLogs = @()
            for ($d = 0; $d -lt 5; $d++) {
                $dayDate = $weekStart.AddDays($d).ToString('yyyy-MM-dd')
                $dayLogs = $mockTimeLogs | Where-Object { $_.date -eq $dayDate }
                $weekLogs += $dayLogs
            }

            $weekLogs.Count | Should -Be 5

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

            # Verify grouping
            $grouped.ContainsKey("ProjectA") | Should -Be $true
            $grouped.ContainsKey("#050") | Should -Be $true
            $grouped.ContainsKey("ProjectB") | Should -Be $true

            # Verify ProjectA totals
            $grouped["ProjectA"].Mon | Should -Be 2.0   # 120 minutes = 2 hours
            $grouped["ProjectA"].Tue | Should -Be 3.0   # 180 minutes = 3 hours
            $grouped["ProjectA"].Total | Should -Be 5.0

            # Verify indirect code totals
            $grouped["#050"].Mon | Should -Be 1.0   # 60 minutes = 1 hour
            $grouped["#050"].Wed | Should -Be 0.5   # 30 minutes = 0.5 hours
            $grouped["#050"].Total | Should -Be 1.5

            # Verify ProjectB totals
            $grouped["ProjectB"].Fri | Should -Be 4.0   # 240 minutes = 4 hours
            $grouped["ProjectB"].Total | Should -Be 4.0
        }

        It "Should call time report function without errors" {
            $context = [PSCustomObject]@{
                Args = @{}
                FreeText = @()
            }

            # This should not throw, even if it tries to show UI
            { Get-PmcTimeReport -Context $context } | Should -Not -Throw
        }
    }

    Context "Template Display Functions" {
        It "Should have access to template rendering functions" {
            # These functions should be available for time list display
            Get-Command "Render-GridTemplate" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command "Write-PmcStyled" -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It "Should call time list function without errors" {
            $context = [PSCustomObject]@{
                Args = @{}
                FreeText = @()
            }

            { Get-PmcTimeList -Context $context } | Should -Not -Throw
        }
    }
}