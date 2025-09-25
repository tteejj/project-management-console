# Test highlighting
$VerbosePreference = 'SilentlyContinue'
$ErrorActionPreference = 'SilentlyContinue'

try {
    Import-Module ./module/Pmc.Strict -Force -ErrorAction Stop
    Write-Host "Module loaded successfully"

    # Test style access
    $selectedStyle = Get-PmcStyle 'Selected'
    Write-Host "Selected style: $($selectedStyle | ConvertTo-Json -Compress)"

    # Test ANSI color generation
    $display = [PmcDataDisplay]::new(@(), @{})
    $testText = "TEST HIGHLIGHT"
    $styledText = $display.ConvertPmcStyleToAnsi($testText, $selectedStyle, @{})
    Write-Host "Styled text: '$styledText'"

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Full error: $($_ | Out-String)"
}