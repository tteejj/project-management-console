# ExcelComReader.ps1 - COM automation for reading Excel files
#
# Provides COM-based Excel reading capabilities
# Can attach to running Excel instance or open files programmatically
#
# Usage:
#   $reader = [ExcelComReader]::new()
#   $reader.AttachToRunningExcel()
#   $value = $reader.ReadCell("W3")
#   $reader.Close()

using namespace System
using namespace System.Runtime.InteropServices

Set-StrictMode -Version Latest

class ExcelComReader {
    # COM objects
    hidden [object]$_excelApp = $null
    hidden [object]$_workbook = $null
    hidden [object]$_worksheet = $null
    hidden [bool]$_isAttached = $false  # Did we create Excel or attach to existing?

    # State
    [bool]$IsOpen = $false
    [string]$FilePath = ""
    [int]$ActiveSheet = 1

    # Constructor
    ExcelComReader() {
        # Nothing to initialize
    }

    # Validate Excel cell address format (e.g., "A1", "W3", "AA100")
    hidden [bool] IsValidCellAddress([string]$address) {
        return $address -match '^[A-Z]+\d+$'
    }

    # Attach to running Excel instance
    [void] AttachToRunningExcel() {
        try {
            $this._excelApp = [Marshal]::GetActiveObject("Excel.Application")
            $this._isAttached = $true

            if ($this._excelApp.Workbooks.Count -gt 0) {
                $this._workbook = $this._excelApp.ActiveWorkbook
                if ($this._workbook.Worksheets.Count -gt 0) {
                    $this._worksheet = $this._workbook.ActiveSheet
                    $this.ActiveSheet = $this._worksheet.Index
                }
            }

            $this.IsOpen = $true
            Write-PmcTuiLog "ExcelComReader: Attached to running Excel instance" "INFO"

        } catch {
            Write-PmcTuiLog "ExcelComReader: Failed to attach to Excel - $_" "ERROR"
            throw "Could not attach to running Excel. Is Excel running?"
        }
    }

    # Open Excel file programmatically
    [void] OpenFile([string]$filePath) {
        if (-not (Test-Path $filePath)) {
            throw "File not found: $filePath"
        }

        try {
            $this._excelApp = New-Object -ComObject Excel.Application
            $this._excelApp.Visible = $false
            $this._excelApp.DisplayAlerts = $false
            $this._isAttached = $false

            $this._workbook = $this._excelApp.Workbooks.Open($filePath)
            if ($this._workbook.Worksheets.Count -gt 0) {
                $this._worksheet = $this._workbook.Worksheets.Item(1)
                $this.ActiveSheet = 1
            }

            $this.FilePath = $filePath
            $this.IsOpen = $true
            Write-PmcTuiLog "ExcelComReader: Opened file $filePath" "INFO"

        } catch {
            Write-PmcTuiLog "ExcelComReader: Failed to open file - $_" "ERROR"
            $this.Close()
            throw "Could not open Excel file: $_"
        }
    }

    # Set active worksheet by index (1-based)
    [void] SetActiveSheet([int]$sheetIndex) {
        if (-not $this.IsOpen -or $null -eq $this._workbook) {
            throw "No workbook is open"
        }

        if ($sheetIndex -lt 1 -or $sheetIndex -gt $this._workbook.Worksheets.Count) {
            throw "Sheet index out of range: $sheetIndex (workbook has $($this._workbook.Worksheets.Count) sheets)"
        }

        $this._worksheet = $this._workbook.Worksheets.Item($sheetIndex)
        $this.ActiveSheet = $sheetIndex
    }

    # Set active worksheet by name
    [void] SetActiveSheetByName([string]$sheetName) {
        if (-not $this.IsOpen -or $null -eq $this._workbook) {
            throw "No workbook is open"
        }

        try {
            $this._worksheet = $this._workbook.Worksheets.Item($sheetName)
            $this.ActiveSheet = $this._worksheet.Index
        } catch {
            throw "Sheet not found: $sheetName"
        }
    }

    # Read single cell value
    [object] ReadCell([string]$cellAddress) {
        if (-not $this.IsOpen -or $null -eq $this._worksheet) {
            throw "No worksheet is active"
        }

        if (-not $this.IsValidCellAddress($cellAddress)) {
            throw "Invalid Excel cell address: $cellAddress (expected format like 'A1' or 'W3')"
        }

        $cell = $null
        try {
            $cell = $this._worksheet.Range($cellAddress)
            $value = $cell.Value2
            return $value
        } catch {
            Write-PmcTuiLog "ExcelComReader: Error reading cell $cellAddress - $_" "ERROR"
            return $null
        } finally {
            if ($null -ne $cell) {
                [Marshal]::ReleaseComObject($cell) | Out-Null
            }
        }
    }

    # Read range of cells (returns hashtable of address => value)
    [hashtable] ReadRange([string]$startCell, [string]$endCell) {
        if (-not $this.IsOpen -or $null -eq $this._worksheet) {
            throw "No worksheet is active"
        }

        if (-not $this.IsValidCellAddress($startCell)) {
            throw "Invalid Excel cell address: $startCell (expected format like 'A1' or 'W3')"
        }
        if (-not $this.IsValidCellAddress($endCell)) {
            throw "Invalid Excel cell address: $endCell (expected format like 'A1' or 'W3')"
        }

        $cellData = @{}
        $range = $null
        $cellsToRelease = [System.Collections.ArrayList]::new()

        try {
            $range = $this._worksheet.Range("$startCell`:$endCell")

            if ($null -ne $range -and $null -ne $range.Cells) {
                foreach ($cell in $range.Cells) {
                    $address = $cell.Address($false, $false)  # Get address like "W3"
                    $cellData[$address] = $cell.Value2
                    [void]$cellsToRelease.Add($cell)
                }
            }

            return $cellData

        } catch {
            Write-PmcTuiLog "ExcelComReader: Error reading range $startCell`:$endCell - $_" "ERROR"
            return $cellData
        } finally {
            # Release all cell COM objects
            foreach ($cell in $cellsToRelease) {
                try {
                    [Marshal]::ReleaseComObject($cell) | Out-Null
                } catch { }
            }
            # Release range COM object
            if ($null -ne $range) {
                try {
                    [Marshal]::ReleaseComObject($range) | Out-Null
                } catch { }
            }
        }
    }

    # Read multiple specific cells (returns hashtable of address => value)
    [hashtable] ReadCells([array]$cellAddresses) {
        if (-not $this.IsOpen -or $null -eq $this._worksheet) {
            throw "No worksheet is active"
        }

        $cellData = @{}

        foreach ($address in $cellAddresses) {
            try {
                $value = $this.ReadCell($address)
                $cellData[$address] = $value
            } catch {
                Write-PmcTuiLog "ExcelComReader: Error reading cell $address - $_" "WARN"
                $cellData[$address] = $null
            }
        }

        return $cellData
    }

    # Get worksheet names
    [array] GetSheetNames() {
        if (-not $this.IsOpen -or $null -eq $this._workbook) {
            return @()
        }

        $names = @()
        $sheets = $null
        try {
            $sheets = $this._workbook.Worksheets
            foreach ($sheet in $sheets) {
                $names += $sheet.Name
                try {
                    [Marshal]::ReleaseComObject($sheet) | Out-Null
                } catch { }
            }
        } finally {
            if ($null -ne $sheets) {
                try {
                    [Marshal]::ReleaseComObject($sheets) | Out-Null
                } catch { }
            }
        }
        return $names
    }

    # Close and cleanup
    # NOTE: Caller MUST call Close() explicitly - PowerShell classes do not support finalizers
    [void] Close() {
        if ($this.IsOpen) {
            # Isolate each cleanup operation to prevent cascading failures

            # Release worksheet COM object
            if ($null -ne $this._worksheet) {
                try {
                    [Marshal]::ReleaseComObject($this._worksheet) | Out-Null
                } catch {
                    Write-PmcTuiLog "ExcelComReader: Error releasing worksheet COM object - $_" "WARN"
                }
            }

            # Close and release workbook
            if ($null -ne $this._workbook -and -not $this._isAttached) {
                try {
                    $this._workbook.Close($false)  # Don't save changes
                } catch {
                    Write-PmcTuiLog "ExcelComReader: Error closing workbook - $_" "WARN"
                }
                try {
                    [Marshal]::ReleaseComObject($this._workbook) | Out-Null
                } catch {
                    Write-PmcTuiLog "ExcelComReader: Error releasing workbook COM object - $_" "WARN"
                }
            }

            # Quit and release Excel app
            if ($null -ne $this._excelApp -and -not $this._isAttached) {
                try {
                    $this._excelApp.Quit()
                } catch {
                    Write-PmcTuiLog "ExcelComReader: Error quitting Excel - $_" "WARN"
                }
                try {
                    [Marshal]::ReleaseComObject($this._excelApp) | Out-Null
                } catch {
                    Write-PmcTuiLog "ExcelComReader: Error releasing Excel COM object - $_" "WARN"
                }
            }

            $this._workbook = $null
            $this._worksheet = $null
            $this._excelApp = $null
            $this.IsOpen = $false

            Write-PmcTuiLog "ExcelComReader: Closed" "INFO"
        }
    }
}
