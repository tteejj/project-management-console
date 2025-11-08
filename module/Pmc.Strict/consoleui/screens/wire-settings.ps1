#!/usr/bin/env pwsh
# Wire up SettingsScreen to all screen menus

$files = Get-ChildItem "/home/teej/pmc/module/Pmc.Strict/consoleui/screens/*.ps1" | Where-Object { $_.Name -ne 'wire-settings.ps1' -and $_.Name -ne 'add-task-metadata-display.ps1' }

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw

    # Check if this file has the stub
    if ($content -match 'Settings.*not.*implemented') {
        Write-Host "Processing $($file.Name)..."

        # Replace the stub with actual navigation
        $content = $content -replace '\$optionsMenu\.Items\.Add\(\[PmcMenuItem\]::new\("Settings", ''S'', \{ Write-Host "Settings not (yet )?implemented" \}\)\)', @'
$optionsMenu.Items.Add([PmcMenuItem]::new("Settings", 'S', {
            . "$PSScriptRoot/SettingsScreen.ps1"
            $global:PmcApp.PushScreen((New-Object SettingsScreen))
        }))
'@

        Set-Content $file.FullName $content -NoNewline
        Write-Host "  Updated successfully"
    }
}

Write-Host "Done!"
