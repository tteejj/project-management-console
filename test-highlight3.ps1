# Test just the color conversion
$VerbosePreference = 'SilentlyContinue'
$ErrorActionPreference = 'Continue'

# Load only necessary files in order
. ./module/Pmc.Strict/src/Types.ps1
. ./module/Pmc.Strict/src/State.ps1
. ./module/Pmc.Strict/src/Config.ps1 2>$null
. ./module/Pmc.Strict/src/Debug.ps1 2>$null
. ./module/Pmc.Strict/src/Security.ps1 2>$null
. ./module/Pmc.Strict/src/Theme.ps1 2>$null
. ./module/Pmc.Strict/src/UI.ps1 2>$null
. ./module/Pmc.Strict/src/PraxisVT.ps1 2>$null

Write-Host "Basic files loaded, testing color conversion..."

# Initialize theme system
Initialize-PmcThemeSystem 2>$null

# Test style access
$selectedStyle = Get-PmcStyle 'Selected'
Write-Host "Selected style: $($selectedStyle | ConvertTo-Json -Compress)"

# Test VT color functions directly
$bgCode = [PmcVT]::BgRGB(0, 120, 212)  # #0078d4 = rgb(0,120,212)
$fgCode = [PmcVT]::FgRGB(255, 255, 255)  # White
$resetCode = [PmcVT]::Reset()

Write-Host "Background code: '$bgCode'"
Write-Host "Foreground code: '$fgCode'"
Write-Host "Reset code: '$resetCode'"

$testText = "TEST HIGHLIGHT"
$styledText = "$bgCode$fgCode$testText$resetCode"
Write-Host "Final styled text: [$styledText]"

# Show raw bytes
$bytes = [System.Text.Encoding]::UTF8.GetBytes($styledText)
Write-Host "Raw bytes: $($bytes -join ',')"