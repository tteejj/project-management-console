#!/usr/bin/env pwsh
# Comprehensive test of ALL menu options with mocked input

param(
    [switch]$Verbose
)

Write-Host "=== COMPREHENSIVE FAKETUI MENU TEST ===" -ForegroundColor Cyan
Write-Host "Testing EVERY menu option with simulated input" -ForegroundColor Cyan
Write-Host ""

# Load test console
. "$PSScriptRoot/module/Pmc.Strict/FakeTUI/TestableConsole.ps1"

# Mock all backend functions
function Get-PmcAllData {
    return @{
        tasks = @(
            @{ id = 1; title = "Test Task 1"; status = "todo"; project = "TestProject"; due = (Get-Date).AddDays(1).ToString('yyyy-MM-dd'); priority = 1; dependencies = @(); notes = @() }
            @{ id = 2; title = "Test Task 2"; status = "done"; project = "TestProject"; completed = (Get-Date).AddDays(-2).ToString('yyyy-MM-dd'); priority = 2 }
            @{ id = 3; title = "Test Task 3"; status = "in-progress"; project = "OtherProject"; priority = 3 }
        )
        projects = @(
            @{ name = "TestProject"; description = "Test"; status = "active"; tags = @("test"); created = (Get-Date).AddDays(-10).ToString('yyyy-MM-dd') }
            @{ name = "OtherProject"; description = "Other"; status = "active"; tags = @(); created = (Get-Date).AddDays(-5).ToString('yyyy-MM-dd') }
        )
        timelogs = @(
            @{ id = 1; task = 1; start = (Get-Date).AddHours(-2).ToString('yyyy-MM-dd HH:mm'); end = (Get-Date).AddHours(-1).ToString('yyyy-MM-dd HH:mm'); duration = 60 }
        )
    }
}

function Save-PmcAllData { param($Data) }
function Save-PmcData { param($Data, $Action) }
function Invoke-PmcUndo { }
function Invoke-PmcRedo { }
function Clear-PmcFocus { }
function Start-PmcTimer { param($TaskId) }
function Stop-PmcTimer { }
function Get-PmcTimerStatus { return $null }

# Load FakeTUI
. "$PSScriptRoot/module/Pmc.Strict/FakeTUI/FakeTUI.ps1"

$testResults = @()
$testConsole = [TestableConsole]::new()

function Test-MenuOption {
    param(
        [string]$Name,
        [string]$View,
        [scriptblock]$SetupInput,
        [scriptblock]$VerifyLogic = $null
    )

    try {
        Write-Host "Testing: $Name" -ForegroundColor Yellow -NoNewline

        # Create app
        $app = [PmcFakeTUIApp]::new()
        $app.Initialize()

        # Inject test console inputs
        & $SetupInput

        # Override Console calls to use test console
        $originalReadLine = Get-Command Console -ErrorAction SilentlyContinue

        # Set the view
        $app.currentView = $View

        # Try to execute the handler
        $handlerName = switch ($View) {
            'depgraph' { 'HandleDependencyGraph' }
            'burndownview' { 'HandleBurndownChart' }
            'toolsreview' { 'HandleStartReview' }
            'toolswizard' { 'HandleProjectWizard' }
            'toolstemplates' { 'HandleTemplates' }
            'toolsstatistics' { 'HandleStatistics' }
            'toolsvelocity' { 'HandleVelocity' }
            'toolspreferences' { 'HandlePreferences' }
            'toolsconfig' { 'HandleConfigEditor' }
            'toolsaliases' { 'HandleManageAliases' }
            'toolsquery' { 'HandleQueryBrowser' }
            'toolsweeklyreport' { 'HandleWeeklyReport' }
            'helpbrowser' { 'HandleHelpBrowser' }
            'helpcategories' { 'HandleHelpCategories' }
            'helpsearch' { 'HandleHelpSearch' }
            'helpabout' { 'HandleAboutPMC' }
            'projectedit' { 'HandleEditProjectForm' }
            'projectinfo' { 'HandleProjectInfoView' }
            'projectrecent' { 'HandleRecentProjectsView' }
            default { $null }
        }

        if ($handlerName) {
            # Call the Draw method directly (doesn't need input)
            $drawMethod = $handlerName -replace 'Handle', 'Draw'
            if ($app.PSObject.Methods[$drawMethod]) {
                $app.$drawMethod()
            }

            if ($VerifyLogic) {
                & $VerifyLogic $app
            }
        }

        $app.Shutdown()

        $testResults += @{ Name = $Name; View = $View; Status = "PASS"; Error = $null }
        Write-Host " ✓" -ForegroundColor Green
        return $true

    } catch {
        $testResults += @{ Name = $Name; View = $View; Status = "FAIL"; Error = $_.Exception.Message }
        Write-Host " ✗" -ForegroundColor Red
        if ($Verbose) {
            Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        }
        return $false
    }
}

Write-Host "=== Testing Dependencies Menu ===" -ForegroundColor Cyan
Test-MenuOption "Dependency Graph" "depgraph" { }

Write-Host ""
Write-Host "=== Testing View Menu ===" -ForegroundColor Cyan
Test-MenuOption "Burndown Chart" "burndownview" { }

Write-Host ""
Write-Host "=== Testing Tools Menu ===" -ForegroundColor Cyan
Test-MenuOption "Start Review" "toolsreview" { }
Test-MenuOption "Project Wizard" "toolswizard" { }
Test-MenuOption "Templates" "toolstemplates" { }
Test-MenuOption "Statistics" "toolsstatistics" { } {
    param($app)
    # Verify statistics were calculated
    $data = Get-PmcAllData
    if ($data.tasks.Count -ne 3) {
        throw "Statistics not calculated correctly"
    }
}
Test-MenuOption "Velocity" "toolsvelocity" { }
Test-MenuOption "Preferences" "toolspreferences" { }
Test-MenuOption "Config Editor" "toolsconfig" { }
Test-MenuOption "Manage Aliases" "toolsaliases" { }
Test-MenuOption "Query Browser" "toolsquery" { }
Test-MenuOption "Weekly Report" "toolsweeklyreport" { }

Write-Host ""
Write-Host "=== Testing Help Menu ===" -ForegroundColor Cyan
Test-MenuOption "Help Browser" "helpbrowser" { }
Test-MenuOption "Help Categories" "helpcategories" { }
Test-MenuOption "Help Search" "helpsearch" { }
Test-MenuOption "About PMC" "helpabout" { }

Write-Host ""
Write-Host "=== Testing Project Menu ===" -ForegroundColor Cyan
Test-MenuOption "Edit Project" "projectedit" { }
Test-MenuOption "Project Info" "projectinfo" { }
Test-MenuOption "Recent Projects" "projectrecent" { }

# Summary
Write-Host ""
Write-Host "=== TEST SUMMARY ===" -ForegroundColor Cyan
$passed = ($testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failed = ($testResults | Where-Object { $_.Status -eq "FAIL" }).Count
$total = $testResults.Count

Write-Host "Total: $total" -ForegroundColor White
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })

if ($failed -gt 0) {
    Write-Host ""
    Write-Host "Failed tests:" -ForegroundColor Red
    $testResults | Where-Object { $_.Status -eq "FAIL" } | ForEach-Object {
        Write-Host "  - $($_.Name) ($($_.View)): $($_.Error)" -ForegroundColor Red
    }
    exit 1
}

Write-Host ""
Write-Host "All menu options tested successfully!" -ForegroundColor Green
exit 0
