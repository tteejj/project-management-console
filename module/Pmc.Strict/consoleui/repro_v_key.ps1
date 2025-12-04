
# Repro script for 'v' key issue
$moduleRoot = "/home/teej/pmc/module/Pmc.Strict"
$consoleUiRoot = "$moduleRoot/consoleui"

# Mock PmcTuiLog
function Write-PmcTuiLog { param($msg, $level) Write-Host "[$level] $msg" }
$global:PmcTuiLogFile = "/tmp/pmc-repro.log"

# Load dependencies (minimal set)
. "$consoleUiRoot/ZIndex.ps1"
. "$consoleUiRoot/PmcScreen.ps1"
. "$consoleUiRoot/widgets/PmcWidget.ps1"
Get-ChildItem -Path "$consoleUiRoot/widgets" -Filter "*.ps1" | Where-Object { $_.Name -notlike "Test*" } | ForEach-Object { . $_.FullName }
. "$consoleUiRoot/base/StandardListScreen.ps1"
# Load helpers
Get-ChildItem -Path "$consoleUiRoot/helpers" -Filter "*.ps1" | ForEach-Object { . $_.FullName }
try {
    . "$consoleUiRoot/screens/ProjectListScreen.ps1"
    Write-Host "ProjectListScreen loaded successfully"
} catch {
    Write-Host "Error loading ProjectListScreen: $_"
    Write-Host $_.ScriptStackTrace
}

# Mock Container and App
class MockContainer {
    [bool] IsRegistered($name) { return $false }
    [void] Register($name, $factory, $singleton) { Write-Host "Registered $name" }
    [object] Resolve($name) { return $null }
}
$global:PmcContainer = [MockContainer]::new()

class MockApp {
    [void] PushScreen($screen) { Write-Host "Pushed screen: $($screen.GetType().Name)" }
}
$global:PmcApp = [MockApp]::new()

# Instantiate Screen
Write-Host "Creating ProjectListScreen..."
$screen = [ProjectListScreen]::new()

# Simulate 'v' key press
Write-Host "Simulating 'v' key press..."
$keyInfo = [ConsoleKeyInfo]::new('v', [ConsoleKey]::V, $false, $false, $false)

# Call HandleKeyPress
$result = $screen.HandleKeyPress($keyInfo)
Write-Host "HandleKeyPress returned: $result"

# Check logs
Write-Host "Logs:"
Get-Content "/tmp/pmc-flow-debug.log" | Select-Object -Last 5
