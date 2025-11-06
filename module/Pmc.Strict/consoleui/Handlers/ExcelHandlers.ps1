# Excel operation handlers for ConsoleUI
# Multi-step wizard for CAA Excel import, workbook copy, and T2020 txt export



function Invoke-ExcelT2020Wizard {
    param($app)

    # Wizard state
    $config = @{
        SourceWorkbook = $null
        SourceSheet = $null
        DestWorkbook = $null
        DestSheet = $null
        Project = $null
        TxtFields = @()
    }

    # Step 1: Source Workbook
    $app.terminal.Clear()
    $app.menuSystem.DrawMenuBar()
    $app.terminal.WriteAtColor(4, 6, "Excel T2020 Wizard - Step 1/6", [PmcVT100]::Cyan(), "")
    $app.terminal.WriteAt(4, 8, "Select SOURCE Excel Workbook (CAA file)")
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

    # Step 3: Destination Workbook
    $app.terminal.Clear()
    $app.menuSystem.DrawMenuBar()
    $app.terminal.WriteAtColor(4, 6, "Excel T2020 Wizard - Step 3/6", [PmcVT100]::Cyan(), "")
    $app.terminal.WriteAt(4, 8, "Select DESTINATION Excel Workbook")
    $app.terminal.WriteAt(4, 9, "(This will be updated with extracted data)")
    $app.terminal.DrawFooter("Press Enter to browse, Esc to cancel")

    $key = [Console]::ReadKey($true)
    if ($key.Key -eq 'Escape') { $app.currentView = 'main'; $app.DrawLayout(); return }

    $config.DestWorkbook = Browse-ConsoleUIPath -app $app -StartPath $HOME -DirectoriesOnly $false
    if (-not $config.DestWorkbook) {
        Show-InfoMessage -Message "No destination workbook selected" -Title "Cancelled" -Color "Yellow"
        $app.currentView = 'main'; $app.DrawLayout(); return
    }

    # Validate destination workbook exists
    if (-not (Test-Path $config.DestWorkbook)) {
        $app.terminal.Clear()
        $app.menuSystem.DrawMenuBar()
        $app.terminal.WriteAtColor(4, 6, "Warning: Destination file not found", [PmcVT100]::Yellow(), "")
        $app.terminal.WriteAt(4, 8, "File: $($config.DestWorkbook)")
        $app.terminal.WriteAt(4, 10, "The destination workbook does not exist.")
        $app.terminal.WriteAt(4, 11, "Copy operation may fail without a template file.")
        $app.terminal.WriteAt(4, 13, "Recommendation: Create/select an existing .xlsm template first.")
        $app.terminal.DrawFooter("Enter:Continue anyway  Esc:Cancel and start over")
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq 'Escape') { $app.currentView = 'main'; $app.DrawLayout(); return }
    }

    # Step 4: Destination Sheet
    try {
        if (Test-Path $config.DestWorkbook) {
            $dstWb = Open-Workbook -Path $config.DestWorkbook
            $sheets = Get-WorksheetNames -Workbook $dstWb
            Close-Workbook -Workbook $dstWb

            if ($sheets.Count -gt 0) {
                $config.DestSheet = Show-SelectList -app $app -Title " Select DESTINATION Sheet " -Options $sheets
            }
        }

        if (-not $config.DestSheet) {
            # Manual entry for new sheet
            $app.terminal.Clear()
            $app.menuSystem.DrawMenuBar()
            $app.terminal.WriteAtColor(4, 6, "Enter Destination Sheet Name:", [PmcVT100]::Yellow(), "")
            $app.terminal.WriteAt(4, 8, "")
            [Console]::SetCursorPosition(4, 8)
            $config.DestSheet = [Console]::ReadLine()
            if ([string]::IsNullOrWhiteSpace($config.DestSheet)) {
                $config.DestSheet = "Output"
            }
        }
    } catch {
        $config.DestSheet = "Output"
    } finally {
        Close-ExcelApp
    }

    # Step 5: Project Selection (Optional)
    $app.terminal.Clear()
    $app.menuSystem.DrawMenuBar()
    $app.terminal.WriteAtColor(4, 6, "Excel T2020 Wizard - Step 5/6", [PmcVT100]::Cyan(), "")
    $app.terminal.WriteAt(4, 8, "Attach extracted data to a project? (Optional)")
    $app.terminal.WriteAt(4, 10, "Y = Select Project")
    $app.terminal.WriteAt(4, 11, "N = Skip (no project attachment)")
    $app.terminal.DrawFooter("Y/N")

    $key = [Console]::ReadKey($true)
    if ($key.Key -eq 'Y') {
        try {
            $data = Get-PmcAllData
            $projectNames = @($data.projects | ForEach-Object {
                if ($_ -is [string]) { $_ }
                elseif ($_.PSObject.Properties['name']) { $_.name }
            } | Where-Object { $_ } | Sort-Object -Unique)

            if ($projectNames.Count -gt 0) {
                $config.Project = Show-SelectList -Title " Select Project " -Options $projectNames
            } else {
                Show-InfoMessage -Message "No projects found" -Title "Info" -Color "Yellow"
            }
        } catch {
            Show-InfoMessage -Message "Error loading projects: $_" -Title "Error" -Color "Red"
        }
    }

    # Step 6: Field Mapping & Txt Configuration
    $app.terminal.Clear()
    $app.menuSystem.DrawMenuBar()
    $app.terminal.WriteAtColor(4, 6, "Excel T2020 Wizard - Step 6/6", [PmcVT100]::Cyan(), "")
    $app.terminal.WriteAt(4, 8, "Configure Field Mappings & txt Export")
    $app.terminal.WriteAt(4, 10, "Current: $($Global:ExcelT2020_Mappings.Count) field mappings")
    $app.terminal.WriteAt(4, 12, "M = Edit Field Mappings (Add/Edit/Delete)")
    $app.terminal.WriteAt(4, 13, "T = Select txt Export Fields")
    $app.terminal.WriteAt(4, 14, "C = Continue with current settings")
    $app.terminal.DrawFooter("M/T/C")

    $key = [Console]::ReadKey($true)
    if ($key.Key -eq 'M') {
        Invoke-FieldMappingEditor -app $app
    }
    if ($key.Key -eq 'T') {
        Invoke-TxtFieldSelector -app $app
    }

    # Execute Workflow
    Invoke-ExcelWorkflowExecution -app $app -Config $config
}

function Invoke-TxtFieldSelector {
    param($app)

    $selected = 0
    $topIndex = 0

    while ($true) {
        $app.terminal.Clear()
        $app.menuSystem.DrawMenuBar()

        $app.terminal.WriteAtColor(4, 3, " T2020 txt Export Field Selection ", [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $app.terminal.WriteAt(4, 5, "Toggle fields to include in txt export (Space to toggle)")

        $y = 7
        $maxVisible = [Math]::Min(30, $app.terminal.Height - 10)

        if ($selected -lt $topIndex) { $topIndex = $selected }
        if ($selected -ge ($topIndex + $maxVisible)) { $topIndex = $selected - $maxVisible + 1 }

        for ($i = $topIndex; $i -lt [Math]::Min($topIndex + $maxVisible, $Global:ExcelT2020_Mappings.Count); $i++) {
            $mapping = $Global:ExcelT2020_Mappings[$i]
            $checkbox = if ($mapping.IncludeInTxt) { "[X]" } else { "[ ]" }
            $prefix = if ($i -eq $selected) { "> " } else { "  " }
            $color = if ($i -eq $selected) { [PmcVT100]::Yellow() } else { "" }

            $line = "$prefix$checkbox $($mapping.Field)"
            $app.terminal.WriteAtColor(4, $y++, $line, $color, "")
        }

        $app.terminal.DrawFooter("↑/↓:Navigate  Space:Toggle  Enter:Done")

        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            'UpArrow' { if ($selected -gt 0) { $selected-- } }
            'DownArrow' { if ($selected -lt $Global:ExcelT2020_Mappings.Count - 1) { $selected++ } }
            'Spacebar' {
                $Global:ExcelT2020_Mappings[$selected].IncludeInTxt = -not $Global:ExcelT2020_Mappings[$selected].IncludeInTxt
            }
            'Enter' { return }
            'Escape' { return }
        }
    }
}

function Invoke-ExcelWorkflowExecution {
    param($app, $Config)

    $app.terminal.Clear()
    $app.menuSystem.DrawMenuBar()
    $app.terminal.WriteAtColor(4, 6, "Executing Excel T2020 Workflow...", [PmcVT100]::Yellow(), "")

    $y = 8
    $result = @{ Success = $true; Errors = @() }

    try {
        # Extract data from source
        $app.terminal.WriteAt(4, $y++, "1. Extracting data from source workbook...")
        $extract = Extract-T2020Fields -SourcePath $Config.SourceWorkbook -SourceSheetName $Config.SourceSheet

        if (-not $extract.Success) {
            $result.Success = $false
            $result.Errors += $extract.Error
            $app.terminal.WriteAtColor(4, $y++, "   ✗ Failed: $($extract.Error)", [PmcVT100]::Red(), "")
        } else {
            $app.terminal.WriteAtColor(4, $y++, "   ✓ Extracted $($extract.Data.Keys.Count) fields", [PmcVT100]::Green(), "")
        }

        # Copy to destination workbook
        $app.terminal.WriteAt(4, $y++, "2. Copying to destination workbook...")
        $copyResult = Copy-T2020ForFile -SourcePath $Config.SourceWorkbook -DestinationPath $Config.DestWorkbook -SourceSheetName $Config.SourceSheet -DestSheetName $Config.DestSheet

        if (-not $copyResult.Success) {
            $result.Success = $false
            $result.Errors += $copyResult.Error
            $app.terminal.WriteAtColor(4, $y++, "   ✗ Failed: $($copyResult.Error)", [PmcVT100]::Red(), "")
        } else {
            $app.terminal.WriteAtColor(4, $y++, "   ✓ Data copied to $($Config.DestWorkbook)", [PmcVT100]::Green(), "")
        }

        # Export to txt
        $app.terminal.WriteAt(4, $y++, "3. Exporting to T2020 txt file...")
        $txtResult = Export-T2020ToTxt -Data $extract.Data

        if (-not $txtResult.Success) {
            $result.Success = $false
            $result.Errors += $txtResult.Error
            $app.terminal.WriteAtColor(4, $y++, "   ✗ Failed: $($txtResult.Error)", [PmcVT100]::Red(), "")
        } else {
            $app.terminal.WriteAtColor(4, $y++, "   ✓ Exported to $($txtResult.Path)", [PmcVT100]::Green(), "")
        }

        # Attach to project if selected
        if ($Config.Project) {
            $app.terminal.WriteAt(4, $y++, "4. Attaching data to project '$($Config.Project)'...")
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
                    $proj | Add-Member -NotePropertyName 'excelData' -NotePropertyValue @{
                        source = $Config.SourceWorkbook
                        imported = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                        sourceSheet = $Config.SourceSheet
                        destWorkbook = $Config.DestWorkbook
                        destSheet = $Config.DestSheet
                        txtExport = $txtResult.Path
                        fields = $extract.Data
                    } -Force

                    Save-PmcData -Data $data -Action "Attached Excel data to project $($Config.Project)"
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
            $app.terminal.WriteAtColor(4, $y++, "✓✓✓ Workflow completed successfully! ✓✓✓", [PmcVT100]::Green(), "")
        } else {
            $app.terminal.WriteAtColor(4, $y++, "Workflow completed with errors", [PmcVT100]::Yellow(), "")
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

function Invoke-ExcelT2020Handler {
    param($app)
    Invoke-ExcelT2020Wizard -app $app
}

function Invoke-ExcelConfigHandler {
    param($app)
    # Legacy - now using wizard
    Invoke-ExcelT2020Wizard -app $app
}

function Invoke-ExcelPreviewHandler {
    param($app)

    $app.terminal.Clear()
    $app.menuSystem.DrawMenuBar()

    $title = " Excel Preview "
    $titleX = ($app.terminal.Width - $title.Length) / 2
    $app.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

    $y = 6
    $app.terminal.WriteAt(4, $y++, "Select Excel file to preview")
    $app.terminal.DrawFooter("Press Enter to browse, Esc to cancel")

    $key = [Console]::ReadKey($true)
    if ($key.Key -eq 'Escape') { $app.currentView = 'main'; $app.DrawLayout(); return }

    $excelFile = Browse-ConsoleUIPath -app $app -StartPath $HOME -DirectoriesOnly $false
    if (-not $excelFile -or -not (Test-Path $excelFile)) {
        Show-InfoMessage -Message "No file selected or file not found" -Title "Cancelled" -Color "Yellow"
        $app.currentView = 'main'; $app.DrawLayout(); return
    }

    try {
        $srcWb = Open-Workbook -Path $excelFile -ReadOnly
        $sheets = Get-WorksheetNames -Workbook $srcWb

        $selectedSheet = Show-SelectList -Title " Select Sheet to Preview " -Options $sheets
        if (-not $selectedSheet) {
            Close-Workbook -Workbook $srcWb
            Close-ExcelApp
            Show-InfoMessage -Message "Sheet selection cancelled" -Title "Cancelled" -Color "Yellow"
            $app.currentView = 'main'; $app.DrawLayout(); return
        }

        $extract = Extract-T2020Fields -SourcePath $excelFile -SourceSheetName $selectedSheet
        Close-Workbook -Workbook $srcWb

        $app.terminal.Clear()
        $app.menuSystem.DrawMenuBar()
        $app.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $y = 6
        if ($extract.Success) {
            $app.terminal.WriteAtColor(4, $y++, "File: $(Split-Path $excelFile -Leaf)", [PmcVT100]::Cyan(), "")
            $app.terminal.WriteAtColor(4, $y++, "Sheet: $selectedSheet", [PmcVT100]::Cyan(), "")
            $y++
            $app.terminal.WriteAtColor(4, $y++, "Extracted Fields:", [PmcVT100]::Yellow(), "")

            foreach ($field in $extract.Data.Keys) {
                if ($y -ge $app.terminal.Height - 5) { break }
                $value = $extract.Data[$field]
                if ($value -and $value.ToString().Length -gt 50) {
                    $value = $value.ToString().Substring(0, 47) + "..."
                }
                $app.terminal.WriteAt(6, $y++, "$field`: $value")
            }
        } else {
            $app.terminal.WriteAtColor(4, $y, "Failed to extract: $($extract.Error)", [PmcVT100]::Red(), "")
        }
    } catch {
        $app.terminal.WriteAtColor(4, 6, "Error: $_", [PmcVT100]::Red(), "")
    } finally {
        Close-ExcelApp
    }

    $app.terminal.DrawFooter("Press any key to return")
    [Console]::ReadKey($true) | Out-Null

    $app.currentView = 'main'
    $app.DrawLayout()
}

function Invoke-FieldMappingEditor {
    param($app)

    $selected = 0
    $topIndex = 0

    while ($true) {
        $app.terminal.Clear()
        $app.menuSystem.DrawMenuBar()

        $app.terminal.WriteAtColor(4, 3, " Field Mapping Editor ", [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $app.terminal.WriteAt(4, 5, "Current Mappings: $($Global:ExcelT2020_Mappings.Count)")

        $y = 7
        $maxVisible = [Math]::Min(25, $app.terminal.Height - 12)

        if ($selected -lt $topIndex) { $topIndex = $selected }
        if ($selected -ge ($topIndex + $maxVisible)) { $topIndex = $selected - $maxVisible + 1 }

        for ($i = $topIndex; $i -lt [Math]::Min($topIndex + $maxVisible, $Global:ExcelT2020_Mappings.Count); $i++) {
            $mapping = $Global:ExcelT2020_Mappings[$i]
            $txtFlag = if ($mapping.IncludeInTxt) { "[T]" } else { "[ ]" }
            $prefix = if ($i -eq $selected) { "> " } else { "  " }
            $color = if ($i -eq $selected) { [PmcVT100]::Yellow() } else { "" }

            $line = "$prefix$txtFlag $($mapping.Field) | $($mapping.SourceCell) -> $($mapping.DestCell)"
            $app.terminal.WriteAtColor(4, $y++, $line, $color, "")
        }

        $app.terminal.DrawFooter("↑/↓:Nav | A:Add | E:Edit | D:Delete | T:Toggle txt | Enter:Done | Esc:Cancel")

        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            'UpArrow' { if ($selected -gt 0) { $selected-- } }
            'DownArrow' { if ($selected -lt $Global:ExcelT2020_Mappings.Count - 1) { $selected++ } }
            'A' {
                $newMapping = Invoke-AddFieldMapping -app $app
                if ($newMapping) {
                    $Global:ExcelT2020_Mappings += $newMapping
                    # Auto-save after adding
                    Save-ExcelT2020Mappings | Out-Null
                }
            }
            'E' {
                if ($Global:ExcelT2020_Mappings.Count -gt 0) {
                    $edited = Invoke-EditFieldMapping -app $app -Mapping $Global:ExcelT2020_Mappings[$selected]
                    if ($edited) {
                        $Global:ExcelT2020_Mappings[$selected] = $edited
                        # Auto-save after editing
                        Save-ExcelT2020Mappings | Out-Null
                    }
                }
            }
            'D' {
                if ($Global:ExcelT2020_Mappings.Count -gt 0) {
                    $Global:ExcelT2020_Mappings = @($Global:ExcelT2020_Mappings | Where-Object { $_ -ne $Global:ExcelT2020_Mappings[$selected] })
                    if ($selected -ge $Global:ExcelT2020_Mappings.Count) { $selected = [Math]::Max(0, $Global:ExcelT2020_Mappings.Count - 1) }
                    # Auto-save after deleting
                    Save-ExcelT2020Mappings | Out-Null
                }
            }
            'T' {
                if ($Global:ExcelT2020_Mappings.Count -gt 0) {
                    $Global:ExcelT2020_Mappings[$selected].IncludeInTxt = -not $Global:ExcelT2020_Mappings[$selected].IncludeInTxt
                    # Auto-save after toggling
                    Save-ExcelT2020Mappings | Out-Null
                }
            }
            'Enter' { return }
            'Escape' { return }
        }
    }
}

function Invoke-AddFieldMapping {
    param($app)

    $fields = @(
        @{Name='fieldName'; Label='Field Name'; Required=$true}
        @{Name='sourceCell'; Label='Source Cell (e.g., W23)'; Required=$true}
        @{Name='destCell'; Label='Dest Cell (e.g., B2)'; Required=$true}
        @{Name='includeInTxt'; Label='Include in txt? (y/n)'; Required=$false; Default='y'}
    )

    $result = Show-InputForm -Title "Add Field Mapping" -Fields $fields

    if ($result) {
        $fieldName = $result['fieldName']

        # Check for duplicate field names
        $existingField = $Global:ExcelT2020_Mappings | Where-Object { $_.Field -eq $fieldName } | Select-Object -First 1
        if ($existingField) {
            Show-InfoMessage -Message "Field '$fieldName' already exists. Please use Edit to modify it." -Title "Duplicate Field" -Color "Yellow"
            return $null
        }

        $includeTxt = ($result['includeInTxt'] -eq 'y' -or $result['includeInTxt'] -eq 'Y' -or $result['includeInTxt'] -eq 'true')
        return @{
            Field = $fieldName
            SourceCell = $result['sourceCell']
            DestCell = $result['destCell']
            IncludeInTxt = $includeTxt
        }
    }

    return $null
}

function Invoke-EditFieldMapping {
    param($app, $Mapping)

    $fields = @(
        @{Name='fieldName'; Label='Field Name'; Required=$true; Default=$Mapping.Field}
        @{Name='sourceCell'; Label='Source Cell'; Required=$true; Default=$Mapping.SourceCell}
        @{Name='destCell'; Label='Dest Cell'; Required=$true; Default=$Mapping.DestCell}
        @{Name='includeInTxt'; Label='Include in txt? (y/n)'; Required=$false; Default=if($Mapping.IncludeInTxt){'y'}else{'n'}}
    )

    $result = Show-InputForm -Title "Edit Field Mapping" -Fields $fields

    if ($result) {
        $includeTxt = ($result['includeInTxt'] -eq 'y' -or $result['includeInTxt'] -eq 'Y' -or $result['includeInTxt'] -eq 'true')
        return @{
            Field = $result['fieldName']
            SourceCell = $result['sourceCell']
            DestCell = $result['destCell']
            IncludeInTxt = $includeTxt
        }
    }

    return $null
}
