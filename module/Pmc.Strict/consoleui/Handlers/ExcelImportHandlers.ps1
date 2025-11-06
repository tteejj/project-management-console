
# Excel Import Handlers for ConsoleUI

function Invoke-ExcelImportWizard {
    param($app)

    # Wizard state
    $config = @{
        SourceWorkbook = $null
        SourceSheet = $null
        KeyColumn = $null
        ValueColumn = $null
        Project = $null
    }

    # Step 1: Source Workbook
    $app.terminal.Clear()
    $app.menuSystem.DrawMenuBar()
    $app.terminal.WriteAtColor(4, 6, "Excel Import Wizard - Step 1/5", [PmcVT100]::Cyan(), "")
    $app.terminal.WriteAt(4, 8, "Select SOURCE Excel Workbook")
    $app.terminal.DrawFooter("Press Enter to browse, Esc to cancel")

    $key = [Console]::ReadKey($true)
    if ($key.Key -eq 'Escape') { $app.currentView = 'main'; $app.DrawLayout(); return }

    $config.SourceWorkbook = Browse-ConsoleUIPath -app $app -StartPath $HOME -DirectoriesOnly $false
    if (-not $config.SourceWorkbook -or -not (Test-Path $config.SourceWorkbook)) {
        Show-InfoMessage -Message "No source workbook selected" -Title "Cancelled" -Color "Yellow"
        $app.currentView = 'main'; $app.DrawLayout(); return
    }

    # Step 2: Source Sheet
    try {
        $srcWb = Open-Workbook -Path $config.SourceWorkbook -ReadOnly
        $sheets = Get-WorksheetNames -Workbook $srcWb
        Close-Workbook -Workbook $srcWb

        if ($sheets.Count -eq 0) {
            Show-InfoMessage -Message "No worksheets found in workbook" -Title "Error" -Color "Red"
            $app.currentView = 'main'; $app.DrawLayout(); return
        }

        $config.SourceSheet = Show-SelectList -Title " Select SOURCE Sheet " -Options $sheets
        if (-not $config.SourceSheet) {
            $app.currentView = 'main'; $app.DrawLayout(); return
        }
    } catch {
        Show-InfoMessage -Message "Error reading workbook: $_" -Title "Error" -Color "Red"
        Close-ExcelApp
        $app.currentView = 'main'; $app.DrawLayout(); return
    } finally {
        Close-ExcelApp
    }

    # Step 3: Key Column
    $app.terminal.Clear()
    $app.menuSystem.DrawMenuBar()
    $app.terminal.WriteAtColor(4, 6, "Excel Import Wizard - Step 3/5", [PmcVT100]::Cyan(), "")
    $app.terminal.WriteAt(4, 8, "Enter the KEY column (e.g., A)")
    $app.terminal.DrawFooter("Enter column letter, Esc to cancel")
    [Console]::SetCursorPosition(4, 10)
    $config.KeyColumn = [Console]::ReadLine()
    if ([string]::IsNullOrWhiteSpace($config.KeyColumn)) {
        $app.currentView = 'main'; $app.DrawLayout(); return
    }

    # Step 4: Value Column
    $app.terminal.Clear()
    $app.menuSystem.DrawMenuBar()
    $app.terminal.WriteAtColor(4, 6, "Excel Import Wizard - Step 4/5", [PmcVT100]::Cyan(), "")
    $app.terminal.WriteAt(4, 8, "Enter the VALUE column (e.g., B)")
    $app.terminal.DrawFooter("Enter column letter, Esc to cancel")
    [Console]::SetCursorPosition(4, 10)
    $config.ValueColumn = [Console]::ReadLine()
    if ([string]::IsNullOrWhiteSpace($config.ValueColumn)) {
        $app.currentView = 'main'; $app.DrawLayout(); return
    }

    # Step 5: Project Selection
    try {
        $data = Get-PmcAllData
        $projectNames = @($data.projects | ForEach-Object {
            if ($_ -is [string]) { $_ }
            elseif ($_.PSObject.Properties['name']) { $_.name }
        } | Where-Object { $_ } | Sort-Object -Unique)

        if ($projectNames.Count -gt 0) {
            $config.Project = Show-SelectList -Title " Select Project to Import To " -Options $projectNames
        } else {
            Show-InfoMessage -Message "No projects found" -Title "Info" -Color "Yellow"
        }
    } catch {
        Show-InfoMessage -Message "Error loading projects: $_" -Title "Error" -Color "Red"
    }

    if (-not $config.Project) {
        $app.currentView = 'main'; $app.DrawLayout(); return
    }

    # Execute Import
    Invoke-ExcelImportExecution -app $app -Config $config
}

function Invoke-ExcelImportExecution {
    param($app, $Config)

    $app.terminal.Clear()
    $app.menuSystem.DrawMenuBar()
    $app.terminal.WriteAtColor(4, 6, "Executing Excel Import...", [PmcVT100]::Yellow(), "")

    $y = 8
    $result = @{ Success = $true; Errors = @() }

    try {
        # Extract data from source
        $app.terminal.WriteAt(4, $y++, "1. Extracting data from source workbook...")
        $importedData = @{}
        $srcWb = Open-Workbook -Path $Config.SourceWorkbook -ReadOnly
        $ws = Get-Worksheet -Workbook $srcWb -Name $Config.SourceSheet
        $maxRow = $ws.Dimension.Rows
        for ($row = 1; $row -le $maxRow; $row++) {
            $key = $ws.Cells["$($Config.KeyColumn)$row"].Value
            $value = $ws.Cells["$($Config.ValueColumn)$row"].Value
            if ($key) {
                $importedData[$key] = $value
            }
        }
        Close-Workbook -Workbook $srcWb

        if ($importedData.Keys.Count -eq 0) {
            $result.Success = $false
            $result.Errors += "No data found in the specified columns."
            $app.terminal.WriteAtColor(4, $y++, "   ✗ Failed: No data found.", [PmcVT100]::Red(), "")
        } else {
            $app.terminal.WriteAtColor(4, $y++, "   ✓ Extracted $($importedData.Keys.Count) key-value pairs", [PmcVT100]::Green(), "")
        }

        # Attach to project if selected
        if ($Config.Project) {
            $app.terminal.WriteAt(4, $y++, "2. Attaching data to project '$($Config.Project)'...")
            try {
                $data = Get-PmcAllData
                $proj = $data.projects | Where-Object {
                    ($_ -is [string] -and $_ -eq $Config.Project) -or
                    ($_.PSObject.Properties['name'] -and $_.name -eq $Config.Project)
                } | Select-Object -First 1

                if ($proj) {
                    # Find project index for proper update
                    $projIndex = -1
                    for ($i = 0; $i -lt $data.projects.Count; $i++) {
                        $p = $data.projects[$i]
                        if (($p -is [string] -and $p -eq $Config.Project) -or ($p.PSObject.Properties['name'] -and $p.name -eq $Config.Project)) {
                            $projIndex = $i
                            break
                        }
                    }

                    # Convert string project to object if needed using centralized function
                    $proj = ConvertTo-PmcProjectObject -Project $proj -DataArray ([ref]$data.projects) -Index $projIndex

                    # Attach Excel data
                    if (-not $proj.PSObject.Properties['excelData']) {
                        $proj | Add-Member -NotePropertyName 'excelData' -NotePropertyValue @{} -Force
                    }
                    $proj.excelData.importedData = $importedData
                    $proj.excelData.lastImport = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')


                    Save-PmcData -Data $data -Action "Imported Excel data to project $($Config.Project)"
                    $app.terminal.WriteAtColor(4, $y++, "   ✓ Data attached to project", [PmcVT100]::Green(), "")
                } else {
                    $app.terminal.WriteAtColor(4, $y++, "   ! Project not found", [PmcVT100]::Yellow(), "")
                }
            } catch {
                $app.terminal.WriteAtColor(4, $y++, "   ✗ Error: $_", [PmcVT100]::Red(), "")
            }
        }

        $y++
        if ($result.Success) {
            $app.terminal.WriteAtColor(4, $y++, "✓✓✓ Import completed successfully! ✓✓✓", [PmcVT100]::Green(), "")
        } else {
            $app.terminal.WriteAtColor(4, $y++, "Import completed with errors", [PmcVT100]::Yellow(), "")
        }

    } catch {
        $app.terminal.WriteAtColor(4, $y++, "✗ Unexpected error: $_", [PmcVT100]::Red(), "")
    } finally {
        Close-ExcelApp
    }

    $app.terminal.DrawFooter("Press any key to continue")
    [Console]::ReadKey($true) | Out-Null

    $app.currentView = 'main'
    $app.DrawLayout()
}
