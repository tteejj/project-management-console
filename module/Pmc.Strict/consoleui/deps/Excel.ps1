# Excel functions for ConsoleUI

$Global:ExcelApp = $null

function Open-Workbook {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [switch]$ReadOnly
    )

    if (-not $Global:ExcelApp) {
        $Global:ExcelApp = New-Object -ComObject Excel.Application
    }

    $workbook = $Global:ExcelApp.Workbooks.Open($Path, $null, $ReadOnly)
    return $workbook
}

function Get-WorksheetNames {
    param(
        [Parameter(Mandatory=$true)]
        $Workbook
    )

    $sheetNames = @()
    foreach ($sheet in $Workbook.Sheets) {
        $sheetNames += $sheet.Name
    }
    return $sheetNames
}

function Close-Workbook {
    param(
        [Parameter(Mandatory=$true)]
        $Workbook
    )

    $Workbook.Close()
}

function Get-Worksheet {
    param(
        [Parameter(Mandatory=$true)]
        $Workbook,
        [Parameter(Mandatory=$true)]
        [string]$Name
    )

    return $Workbook.Sheets.Item($Name)
}

function Close-ExcelApp {
    if ($Global:ExcelApp) {
        $Global:ExcelApp.Quit()
        $Global:ExcelApp = $null
    }
}