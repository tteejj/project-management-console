# File and Directory Picker for ConsoleUI
# Provides F2-integrated file/folder browser with navigation

function Show-ConsoleUIFooter {
    param($app, [string]$Message)
    try {
        $app.terminal.FillArea(0, $app.terminal.Height - 1, $app.terminal.Width, 1, ' ')
        $app.terminal.WriteAt(2, $app.terminal.Height - 1, $Message)
    } catch {}
}

function Browse-ConsoleUIPath {
    param($app,[string]$StartPath,[bool]$DirectoriesOnly=$false)
    $cwd = if ($StartPath -and (Test-Path $StartPath)) {
        if (Test-Path $StartPath -PathType Leaf) { Split-Path -Parent $StartPath } else { $StartPath }
    } else { (Get-Location).Path }
    $selected = 0; $topIndex = 0
    while ($true) {
        $items = @()
        try { $dirs = @(Get-ChildItem -Force -Directory -LiteralPath $cwd | Sort-Object Name) } catch { $dirs=@() }
        try { $files = if ($DirectoriesOnly) { @() } else { @(Get-ChildItem -Force -File -LiteralPath $cwd | Sort-Object Name) } } catch { $files=@() }
        $items += ([pscustomobject]@{ Kind='Up'; Name='..' })
        foreach ($d in $dirs) { $items += [pscustomobject]@{ Kind='Dir'; Name=$d.Name } }
        foreach ($f in $files) { $items += [pscustomobject]@{ Kind='File'; Name=$f.Name } }
        if ($selected -ge $items.Count) { $selected = [Math]::Max(0, $items.Count-1) }
        if ($selected -lt 0) { $selected = 0 }

        $app.terminal.Clear(); $app.menuSystem.DrawMenuBar()
        $kind = 'File'; if ($DirectoriesOnly) { $kind = 'Folder' }
        $title = " Select $kind "
        $titleX = ($app.terminal.Width - $title.Length) / 2
        $app.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())
        $app.terminal.WriteAtColor(4, 5, "Current: $cwd", [PmcVT100]::Cyan(), "")

        $listTop = 7
        $maxVisible = [Math]::Max(5, [Math]::Min(25, $app.terminal.Height - $listTop - 3))
        if ($selected -lt $topIndex) { $topIndex = $selected }
        if ($selected -ge ($topIndex + $maxVisible)) { $topIndex = $selected - $maxVisible + 1 }
        for ($row=0; $row -lt $maxVisible; $row++) {
            $idx = $topIndex + $row
            $line = ''
            if ($idx -lt $items.Count) {
                $item = $items[$idx]
                $tag = if ($item.Kind -eq 'Dir') { '[D]' } elseif ($item.Kind -eq 'File') { '[F]' } else { '  ' }
                $line = "$tag $($item.Name)"
            }
            $prefix = if (($topIndex + $row) -eq $selected) { '> ' } else { '  ' }
            $color = if (($topIndex + $row) -eq $selected) { [PmcVT100]::Yellow() } else { [PmcVT100]::White() }
            $app.terminal.WriteAtColor(4, $listTop + $row, ($prefix + $line).PadRight($app.terminal.Width - 8), $color, "")
        }
        Show-ConsoleUIFooter $app "↑/↓ scroll  |  Enter: select  |  → open folder  |  ←/Backspace up  |  Esc cancel"
        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            'UpArrow' { if ($selected -gt 0) { $selected--; if ($selected -lt $topIndex) { $topIndex = $selected } } }
            'DownArrow' { if ($selected -lt $items.Count-1) { $selected++; if ($selected -ge $topIndex+$maxVisible) { $topIndex = $selected - $maxVisible + 1 } } }
            'PageUp' { $selected = [Math]::Max(0, $selected - $maxVisible); $topIndex = [Math]::Max(0, $topIndex - $maxVisible) }
            'PageDown' { $selected = [Math]::Min($items.Count-1, $selected + $maxVisible); if ($selected -ge $topIndex+$maxVisible) { $topIndex = $selected - $maxVisible + 1 } }
            'Home' { $selected = 0; $topIndex = 0 }
            'End' { $selected = [Math]::Max(0, $items.Count-1); $topIndex = [Math]::Max(0, $items.Count - $maxVisible) }
            'LeftArrow' {
                try {
                    if ([string]::IsNullOrWhiteSpace($cwd)) { $cwd = ($StartPath ?? (Get-Location).Path) }
                    else {
                        $parent = ''
                        try { $parent = Split-Path -Parent $cwd } catch { $parent = '' }
                        if (-not [string]::IsNullOrWhiteSpace($parent) -and $parent -ne $cwd) { $cwd = $parent }
                    }
                } catch {}
            }
            'Backspace' {
                try {
                    if ([string]::IsNullOrWhiteSpace($cwd)) { $cwd = ($StartPath ?? (Get-Location).Path) }
                    else {
                        $parent = ''
                        try { $parent = Split-Path -Parent $cwd } catch { $parent = '' }
                        if (-not [string]::IsNullOrWhiteSpace($parent) -and $parent -ne $cwd) { $cwd = $parent }
                    }
                } catch {}
            }
            'RightArrow' { if ($items.Count -gt 0) { $it=$items[$selected]; if ($it.Kind -eq 'Dir') { $cwd = Join-Path $cwd $it.Name } } }
            'Escape' { return $null }
            'Enter' {
                if ($items.Count -eq 0) { continue }
                $it = $items[$selected]
                if ($it.Kind -eq 'Up') {
                    try {
                        $parent = ''
                        try { $parent = Split-Path -Parent $cwd } catch { $parent = '' }
                        if (-not [string]::IsNullOrWhiteSpace($parent) -and $parent -ne $cwd) { $cwd = $parent }
                    } catch {}
                }
                elseif ($it.Kind -eq 'Dir') { return (Join-Path $cwd $it.Name) }
                else { return (Join-Path $cwd $it.Name) }
            }
        }
    }
}

function Select-ConsoleUIPathAt {
    param($app,[string]$Hint,[int]$Col,[int]$Row,[string]$StartPath,[bool]$DirectoriesOnly=$false)
    Show-ConsoleUIFooter $app ("$Hint  |  Enter: Pick  |  Tab: Skip  |  Esc: Cancel")
    [Console]::SetCursorPosition($Col, $Row)
    $key = [Console]::ReadKey($true)
    if ($key.Key -eq 'Escape') { Show-ConsoleUIFooter $app "Enter values; Enter = next, Esc = cancel"; return '' }
    if ($key.Key -eq 'Tab') { Show-ConsoleUIFooter $app "Enter values; Enter = next, Esc = cancel"; return '' }
    $sel = Browse-ConsoleUIPath -app $app -StartPath $StartPath -DirectoriesOnly:$DirectoriesOnly
    Show-ConsoleUIFooter $app "Enter values; Enter = next, Esc = cancel"
    return ($sel ?? '')
}

function Get-ConsoleUISelectedProjectName {
    param($app)
    try {
        if ($app.currentView -eq 'projectlist') {
            if ($app.selectedProjectIndex -lt $app.projects.Count) {
                $p = $app.projects[$app.selectedProjectIndex]
                $pname = $null
                if ($p -is [string]) { $pname = $p } else { $pname = $p.name }
                return $pname
            }
        }
        if ($app.filterProject) { return $app.filterProject }
    } catch {}
    return $null
}

function Open-SystemPath {
    param([string]$Path,[bool]$IsDir=$false)
    try {
        if (-not $Path -or -not (Test-Path $Path)) { return $false }
        $isWin = $false
        try { if ($env:OS -like '*Windows*') { $isWin = $true } } catch {}
        if (-not $isWin) { try { if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) { $isWin = $true } } catch {} }
        if ($isWin) {
            if ($IsDir) { Start-Process -FilePath explorer.exe -ArgumentList @("$Path") | Out-Null }
            else { Start-Process -FilePath "$Path" | Out-Null }
            return $true
        } else {
            $cmd = 'xdg-open'
            if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { $cmd = 'gio'; $args = @('open', "$Path") } else { $args = @("$Path") }
            Start-Process -FilePath $cmd -ArgumentList $args | Out-Null
            return $true
        }
    } catch { return $false }
}

function Open-ConsoleUIProjectPath {
    param($app,[string]$Field)
    $projName = Get-ConsoleUISelectedProjectName -app $app
    if (-not $projName) { Show-InfoMessage -Message "Select a project first (Projects → Project List)" -Title "Info" -Color "Yellow"; return }
    try {
        $data = Get-PmcAllData
        $proj = $data.projects | ForEach-Object {
            if ($_ -is [string]) { if ($_ -eq $projName) { $_ } } else { if ($_.name -eq $projName) { $_ } }
        } | Select-Object -First 1
        if (-not $proj) { Show-InfoMessage -Message "Project not found: $projName" -Title "Error" -Color "Red"; return }
        $path = $null
        if ($proj.PSObject.Properties[$Field]) { $path = $proj.$Field }
        if (-not $path -or [string]::IsNullOrWhiteSpace($path)) { Show-InfoMessage -Message "$Field not set for project" -Title "Error" -Color "Red"; return }
        $isDir = ($Field -eq 'ProjFolder')
        if (Open-SystemPath -Path $path -IsDir:$isDir) {
            Show-InfoMessage -Message "Opened: $path" -Title "Success" -Color "Green"
        } else {
            Show-InfoMessage -Message "Failed to open: $path" -Title "Error" -Color "Red"
        }
    } catch {
        Show-InfoMessage -Message "Failed to open: $_" -Title "Error" -Color "Red"
    }
}

function Draw-ConsoleUIProjectFormValues {
    param($app,[int]$RowStart,[hashtable]$Inputs)
    try {
        $app.terminal.WriteAt(28, $RowStart + 0, [string]($Inputs.Name ?? ''))
        $app.terminal.WriteAt(16, $RowStart + 1, [string]($Inputs.Description ?? ''))
        $app.terminal.WriteAt(9,  $RowStart + 2, [string]($Inputs.ID1 ?? ''))
        $app.terminal.WriteAt(9,  $RowStart + 3, [string]($Inputs.ID2 ?? ''))
        $app.terminal.WriteAt(20, $RowStart + 4, [string]($Inputs.ProjFolder ?? ''))
        $app.terminal.WriteAt(14, $RowStart + 5, [string]($Inputs.CAAName ?? ''))
        $app.terminal.WriteAt(17, $RowStart + 6, [string]($Inputs.RequestName ?? ''))
        $app.terminal.WriteAt(11, $RowStart + 7, [string]($Inputs.T2020 ?? ''))
        $app.terminal.WriteAt(32, $RowStart + 8, [string]($Inputs.AssignedDate ?? ''))
        $app.terminal.WriteAt(27, $RowStart + 9, [string]($Inputs.DueDate ?? ''))
        $app.terminal.WriteAt(26, $RowStart + 10, [string]($Inputs.BFDate ?? ''))
    } catch {}
}

Export-ModuleMember -Function Browse-ConsoleUIPath, Select-ConsoleUIPathAt, Get-ConsoleUISelectedProjectName, Open-SystemPath, Open-ConsoleUIProjectPath, Draw-ConsoleUIProjectFormValues, Show-ConsoleUIFooter
