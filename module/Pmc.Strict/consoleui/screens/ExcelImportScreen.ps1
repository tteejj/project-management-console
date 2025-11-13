using namespace System.Collections.Generic
using namespace System.Text

# ExcelImportScreen - Import project from Excel
# Multi-step wizard: Source -> Profile -> Preview -> Import

Set-StrictMode -Version Latest

. "$PSScriptRoot/../PmcScreen.ps1"
. "$PSScriptRoot/../services/ExcelComReader.ps1"
. "$PSScriptRoot/../services/ExcelMappingService.ps1"

<#
.SYNOPSIS
Excel import wizard screen

.DESCRIPTION
Import project data from Excel file:
- Step 1: Choose source (running Excel or file)
- Step 2: Select profile
- Step 3: Preview data
- Step 4: Confirm and import
#>
class ExcelImportScreen : PmcScreen {
    hidden [ExcelComReader]$_reader = $null
    hidden [ExcelMappingService]$_mappingService = $null
    hidden [object]$_activeProfile = $null
    hidden [hashtable]$_previewData = @{}
    hidden [int]$_step = 1
    hidden [int]$_selectedOption = 0
    hidden [string]$_errorMessage = ""
    [TaskStore]$Store = $null  # CRITICAL FIX #1: Add Store property for AddProject() call

    # Static: Register menu items
    static [void] RegisterMenuItems([object]$registry) {
        $registry.AddMenuItem('Projects', 'Import from Excel', 'I', {
            . "$PSScriptRoot/ExcelImportScreen.ps1"
            $global:PmcApp.PushScreen([ExcelImportScreen]::new())
        }, 40)
    }

    # Legacy constructor (backward compatible)
    ExcelImportScreen() : base("ExcelImport", "Import from Excel") {
        $this._InitializeScreen()
    }

    # Container constructor
    ExcelImportScreen([object]$container) : base("ExcelImport", "Import from Excel", $container) {
        $this._InitializeScreen()
    }

    hidden [void] _InitializeScreen() {
        $this._reader = [ExcelComReader]::new()
        $this._mappingService = [ExcelMappingService]::GetInstance()

        # CRITICAL FIX #1: Initialize TaskStore for AddProject() call at line 379
        $this.Store = [TaskStore]::GetInstance()

        # Configure header
        $this.Header.SetBreadcrumb(@("Projects", "Import from Excel"))

        # Configure footer
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Enter", "Next")
        $this.Footer.AddShortcut("Esc", "Cancel")
    }

    [void] OnExit() {
        $this.IsActive = $false
        if ($null -ne $this._reader) {
            $this._reader.Close()
        }
    }

    [string] Render() {
        $sb = [StringBuilder]::new()

        # Render base widgets
        $output = ([PmcScreen]$this).Render()
        $sb.Append($output)

        # Calculate content area
        $contentY = 6
        $contentHeight = $this.TermHeight - 8
        $contentWidth = $this.TermWidth

        $y = $contentY + 2

        # Render based on step
        switch ($this._step) {
            1 { $this._RenderStep1($sb, $y, $contentWidth) }
            2 { $this._RenderStep2($sb, $y, $contentWidth) }
            3 { $this._RenderStep3($sb, $y, $contentWidth) }
            4 { $this._RenderStep4($sb, $y, $contentWidth) }
        }

        # Render error if any
        if (-not [string]::IsNullOrEmpty($this._errorMessage)) {
            $sb.Append($this.Header.BuildMoveTo(2, $this.TermHeight - 5))
            $sb.Append("`e[31mError: $($this._errorMessage)`e[0m")
        }

        return $sb.ToString()
    }

    hidden [void] _RenderStep1([StringBuilder]$sb, [int]$y, [int]$width) {
        # Step 1: Choose source
        $sb.Append($this.Header.BuildMoveTo(2, $y))
        $sb.Append("`e[1mStep 1: Choose Excel Source`e[0m")
        $y += 2

        $options = @(
            "1. Attach to running Excel instance"
            "2. Open Excel file (not implemented - select option 1)"
        )

        for ($i = 0; $i -lt $options.Count; $i++) {
            $sb.Append($this.Header.BuildMoveTo(4, $y + $i))
            if ($i -eq $this._selectedOption) {
                $sb.Append("`e[7m")  # Reverse video
            }
            $sb.Append($options[$i])
            if ($i -eq $this._selectedOption) {
                $sb.Append("`e[0m")
            }
        }
    }

    hidden [void] _RenderStep2([StringBuilder]$sb, [int]$y, [int]$width) {
        # Step 2: Select profile
        $sb.Append($this.Header.BuildMoveTo(2, $y))
        $sb.Append("`e[1mStep 2: Select Import Profile`e[0m")
        $y += 2

        $profiles = @($this._mappingService.GetAllProfiles())
        if ($profiles.Count -eq 0) {
            $sb.Append($this.Header.BuildMoveTo(4, $y))
            $sb.Append("No profiles found. Please create a profile first.")
        } else {
            $activeProfile = $this._mappingService.GetActiveProfile()
            $activeId = if ($activeProfile) { $activeProfile['id'] } else { $null }

            for ($i = 0; $i -lt $profiles.Count; $i++) {
                $profile = $profiles[$i]
                $isActive = if ($profile['id'] -eq $activeId) { " [ACTIVE]" } else { "" }

                $sb.Append($this.Header.BuildMoveTo(4, $y + $i))
                if ($i -eq $this._selectedOption) {
                    $sb.Append("`e[7m")
                }
                $sb.Append("$($i + 1). $($profile['name'])$isActive")
                if ($i -eq $this._selectedOption) {
                    $sb.Append("`e[0m")
                }
            }
        }
    }

    hidden [void] _RenderStep3([StringBuilder]$sb, [int]$y, [int]$width) {
        # Step 3: Preview data
        $sb.Append($this.Header.BuildMoveTo(2, $y))
        $sb.Append("`e[1mStep 3: Preview Import Data`e[0m")
        $y += 2

        if ($null -eq $this._activeProfile) {
            $sb.Append($this.Header.BuildMoveTo(4, $y))
            $sb.Append("No profile selected")
            return
        }

        $sb.Append($this.Header.BuildMoveTo(4, $y))
        $sb.Append("Profile: $($this._activeProfile['name'])")
        $y += 2

        # Show preview data
        $maxRows = 15
        $rowCount = 0

        foreach ($mapping in $this._activeProfile['mappings']) {
            if ($rowCount -ge $maxRows) { break }

            $fieldName = $mapping['display_name']
            $value = if ($this._previewData.ContainsKey($mapping['excel_cell'])) {
                $cellValue = $this._previewData[$mapping['excel_cell']]
                if ($null -eq $cellValue -or [string]::IsNullOrWhiteSpace($cellValue)) {
                    "(empty)"
                } else {
                    $cellValue
                }
            } else {
                "(empty)"
            }

            $required = if ($mapping['required']) { "*" } else { " " }

            $sb.Append($this.Header.BuildMoveTo(4, $y + $rowCount))
            $sb.Append("$required$($fieldName): $value")
            $rowCount++
        }
    }

    hidden [void] _RenderStep4([StringBuilder]$sb, [int]$y, [int]$width) {
        # Step 4: Confirm
        $sb.Append($this.Header.BuildMoveTo(2, $y))
        $sb.Append("`e[1mStep 4: Import Complete`e[0m")
        $y += 2

        $sb.Append($this.Header.BuildMoveTo(4, $y))
        $sb.Append("Project imported successfully!")
        $y += 2

        $sb.Append($this.Header.BuildMoveTo(4, $y))
        $sb.Append("Press Esc to return to project list.")
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        # CRITICAL: Call parent FIRST for MenuBar, F10, Alt+keys, content widgets
        $handled = ([PmcScreen]$this).HandleKeyPress($keyInfo)
        if ($handled) { return $true }

        # Clear error
        $this._errorMessage = ""

        # Up/Down for selection
        if ($keyInfo.Key -eq ([ConsoleKey]::UpArrow)) {
            if ($this._selectedOption -gt 0) {
                $this._selectedOption--
            }
            return $true
        }

        if ($keyInfo.Key -eq ([ConsoleKey]::DownArrow)) {
            $maxOptions = $this._GetMaxOptions()
            if ($this._selectedOption -lt $maxOptions - 1) {
                $this._selectedOption++
            }
            return $true
        }

        # Enter - Next step
        if ($keyInfo.Key -eq ([ConsoleKey]::Enter)) {
            $this._ProcessStep()
            return $true
        }

        # Escape - Cancel/Back
        if ($keyInfo.Key -eq ([ConsoleKey]::Escape)) {
            if ($this._step -eq 1) {
                $global:PmcApp.PopScreen()
            } else {
                $this._step--
                $this._selectedOption = 0
            }
            return $true
        }

        return $false
    }

    hidden [int] _GetMaxOptions() {
        switch ($this._step) {
            1 { return 2 }  # 2 source options
            2 {
                $profiles = @($this._mappingService.GetAllProfiles())
                return $profiles.Count
            }
            default { return 0 }
        }
        return 0  # Explicit return to satisfy PowerShell strict mode
    }

    hidden [void] _ProcessStep() {
        try {
            switch ($this._step) {
                1 {
                    # Step 1: Connect to Excel
                    if ($this._selectedOption -eq 0) {
                        $this._reader.AttachToRunningExcel()
                        $this._step = 2
                        $this._selectedOption = 0
                    } else {
                        $this._errorMessage = "File picker not implemented. Please use option 1."
                    }
                }
                2 {
                    # Step 2: Select profile and read data
                    $profiles = @($this._mappingService.GetAllProfiles())
                    if ($this._selectedOption -lt $profiles.Count) {
                        $this._activeProfile = $profiles[$this._selectedOption]

                        # Read all mapped cells
                        $cellsToRead = @($this._activeProfile['mappings'] | ForEach-Object { $_['excel_cell'] })
                        $this._previewData = $this._reader.ReadCells($cellsToRead)

                        $this._step = 3
                        $this._selectedOption = 0
                    }
                }
                3 {
                    # Step 3: Validate and import
                    $this._ImportProject()
                    $this._step = 4
                    $this._selectedOption = 0
                }
                4 {
                    # Step 4: Done
                    $global:PmcApp.PopScreen()
                }
            }
        } catch {
            $this._errorMessage = $_.Exception.Message
            Write-PmcTuiLog "ExcelImportScreen: Error in step $($this._step) - $_" "ERROR"
        }
    }

    hidden [void] _ImportProject() {
        # Validate profile has mappings
        if ($null -eq $this._activeProfile -or
            -not $this._activeProfile.ContainsKey('mappings') -or
            $null -eq $this._activeProfile['mappings'] -or
            $this._activeProfile['mappings'].Count -eq 0) {
            throw "Active profile has no field mappings configured"
        }

        # Build project data from mappings
        $projectData = @{}

        foreach ($mapping in $this._activeProfile['mappings']) {
            # Get value with existence check
            $value = if ($this._previewData.ContainsKey($mapping['excel_cell'])) {
                $this._previewData[$mapping['excel_cell']]
            } else {
                $null
            }

            # Validate required fields based on data type
            $isEmpty = switch ($mapping['data_type']) {
                'string' { [string]::IsNullOrWhiteSpace($value) }
                'int' { $null -eq $value }
                'bool' { $null -eq $value }
                'date' { $null -eq $value }
                default { $null -eq $value }
            }

            if ($mapping['required'] -and $isEmpty) {
                throw "Required field '$($mapping['display_name'])' is empty"
            }

            # Type conversion with error handling - throw on failure for data integrity
            $convertedValue = switch ($mapping['data_type']) {
                'int' {
                    try {
                        if ($null -eq $value -or $value -eq '') {
                            0
                        } else {
                            [int]$value
                        }
                    } catch {
                        Write-PmcTuiLog "Failed to convert '$value' to int for field $($mapping['display_name']): $_" "ERROR"
                        throw "Cannot convert '$value' to integer for field '$($mapping['display_name'])'"
                    }
                }
                'bool' {
                    try {
                        if ($null -eq $value -or $value -eq '') {
                            $false
                        } else {
                            [bool]$value
                        }
                    } catch {
                        Write-PmcTuiLog "Failed to convert '$value' to bool for field $($mapping['display_name']): $_" "ERROR"
                        throw "Cannot convert '$value' to boolean for field '$($mapping['display_name'])'"
                    }
                }
                'date' {
                    try {
                        if ($null -eq $value -or $value -eq '') {
                            $null
                        } else {
                            [datetime]$value
                        }
                    } catch {
                        Write-PmcTuiLog "Failed to convert '$value' to date for field $($mapping['display_name']): $_" "ERROR"
                        throw "Cannot convert '$value' to date for field '$($mapping['display_name'])'"
                    }
                }
                default {
                    $value
                }
            }

            $projectData[$mapping['project_property']] = $convertedValue
        }

        # CRITICAL FIX #4: Validate project name exists before import
        if (-not $projectData.ContainsKey('name') -or [string]::IsNullOrWhiteSpace($projectData['name'])) {
            throw "Project name is required but not mapped or empty. Please configure a mapping for the 'name' field."
        }

        # Use TaskStore to add project (no Get-PmcAllData bypass!)
        # TaskStore handles ID generation and timestamps automatically
        $success = $this.Store.AddProject($projectData)

        if ($success) {
            Write-PmcTuiLog "ExcelImportScreen: Imported project '$($projectData['name'])'" "INFO"
            # Flush to disk since this is a user-initiated import
            $this.Store.Flush()
        } else {
            Write-PmcTuiLog "ExcelImportScreen: Failed to import project: $($this.Store.LastError)" "ERROR"
            throw "Failed to import project: $($this.Store.LastError)"
        }
    }
}
