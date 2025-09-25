# Test highlighting with direct sourcing
$VerbosePreference = 'SilentlyContinue'
$ErrorActionPreference = 'Continue'

# Direct source the necessary files
. ./module/Pmc.Strict/src/Types.ps1
. ./module/Pmc.Strict/src/State.ps1
. ./module/Pmc.Strict/src/Config.ps1
. ./module/Pmc.Strict/src/Debug.ps1
. ./module/Pmc.Strict/src/Security.ps1
. ./module/Pmc.Strict/src/Theme.ps1
. ./module/Pmc.Strict/src/UI.ps1
. ./module/Pmc.Strict/src/PraxisVT.ps1
. ./module/Pmc.Strict/src/DataDisplay.ps1

Write-Host "Files sourced, testing..."

# Initialize theme system
Initialize-PmcThemeSystem

# Test style access
$selectedStyle = Get-PmcStyle 'Selected'
Write-Host "Selected style: $($selectedStyle | ConvertTo-Json -Compress)"

# Test ANSI color generation
$testText = "TEST HIGHLIGHT"
$display = [PmcDataDisplay]::new(@(), @{})
$styledText = $display.ConvertPmcStyleToAnsi($testText, $selectedStyle, @{})
Write-Host "Raw styled text bytes: $([System.Text.Encoding]::UTF8.GetBytes($styledText) -join ',')"
Write-Host "Styled text visual: [$styledText]"