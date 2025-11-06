#!/usr/bin/env pwsh

Import-Module /home/teej/pmc/module/Pmc.Strict/Pmc.Strict.psd1 -Force
. /home/teej/pmc/module/Pmc.Strict/consoleui/SpeedTUILoader.ps1
. /home/teej/pmc/module/Pmc.Strict/consoleui/PmcApplication.ps1
. /home/teej/pmc/module/Pmc.Strict/consoleui/PmcScreen.ps1
. /home/teej/pmc/module/Pmc.Strict/consoleui/screens/TaskListScreen.ps1

Write-Host "Creating app and screen..."
$app = [PmcApplication]::new()
$screen = [TaskListScreen]::new()
$screen.TermWidth = $app.TermWidth
$screen.TermHeight = $app.TermHeight
$screen.RenderEngine = $app.RenderEngine
$screen.LayoutManager = $app.LayoutManager

Write-Host "Loading data..."
$screen.LoadData()
Write-Host "Tasks loaded: $($screen.Tasks.Count)"

Write-Host "Rendering..."
$app.RenderEngine.BeginFrame()
$output = $screen.Render()
Write-Host "Output length: $($output.Length)"
$app._WriteAnsiToEngine($output)
$app.RenderEngine.EndFrame()

Write-Host "`nPress any key to exit..."
[Console]::ReadKey($true) | Out-Null
