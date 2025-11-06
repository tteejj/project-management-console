# ProjectWizardScreen - Full project creation wizard with F2 file pickers
# Restored from backup (lines 7636-7783)

class ProjectWizardScreen : PmcScreen {
    [hashtable]$inputs = @{}
    [int]$rowStart = 6
    [string]$defaultRoot = ''

    ProjectWizardScreen([PmcConsoleUIApp]$app) : base($app) {
        $this.Name = 'projectwizard'
        try {
            $this.defaultRoot = $Script:DefaultPickerRoot
        } catch {
            $this.defaultRoot = (Get-Location).Path
        }
    }

    [void] OnEnter() {
        $this.inputs = @{}
        $this.DrawForm(0)
        $this.RunWizard()
    }

    [void] DrawForm([int]$ActiveField) {
        $this.Terminal.Clear()
        $this.App.menuSystem.DrawMenuBar()
        $title = " Create New Project "
        $titleX = ($this.Terminal.Width - $title.Length) / 2
        $this.Terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

        $y = $this.rowStart
        $labels = @(
            'Project Name (required):',
            'Description:',
            'ID1:',
            'ID2:',
            'Project Folder:',
            'CAA Name:',
            'Request Name:',
            'T2020:',
            'Assigned Date (yyyy-MM-dd):',
            'Due Date (yyyy-MM-dd):',
            'BF Date (yyyy-MM-dd):'
        )
        for ($i = 0; $i -lt $labels.Count; $i++) {
            $label = $labels[$i]
            if ($ActiveField -eq $i) {
                $this.Terminal.WriteAtColor(2, $y, '> ', [PmcVT100]::Yellow(), "")
                $this.Terminal.WriteAtColor(4, $y, $label, [PmcVT100]::BgBlue(), [PmcVT100]::White())
            } else {
                $this.Terminal.WriteAtColor(4, $y, $label, [PmcVT100]::Yellow(), "")
            }
            $y++
        }

        Show-ConsoleUIFooter -app $this.App -Message "Enter values; Enter = next, Esc = cancel"
    }

    [string] ReadLineAt([int]$col, [int]$row, [bool]$required) {
        [Console]::SetCursorPosition($col, $row)
        [Console]::Write([PmcVT100]::Yellow())
        $buf = ''
        while ($true) {
            $k = [Console]::ReadKey($true)
            switch ($k.Key) {
                'Escape' {
                    [Console]::Write([PmcVT100]::Reset())
                    return $null
                }
                'Enter' {
                    [Console]::Write([PmcVT100]::Reset())
                    if ($required -and [string]::IsNullOrWhiteSpace($buf)) {
                        return $null
                    }
                    return $buf.Trim()
                }
                'Backspace' {
                    if ($buf.Length -gt 0) {
                        $buf = $buf.Substring(0, $buf.Length - 1)
                        [Console]::SetCursorPosition($col, $row)
                        [Console]::Write((' ' * ($buf.Length + 10)))
                        [Console]::SetCursorPosition($col, $row)
                        [Console]::Write($buf)
                    }
                }
                default {
                    $ch = $k.KeyChar
                    if ($ch -and $ch -ne "`0") {
                        $buf += $ch
                        [Console]::Write($ch)
                    }
                }
            }
        }
    }

    [void] RunWizard() {
        # Step 1: Name (required)
        $this.inputs.Name = $this.ReadLineAt(28, ($this.rowStart + 0), $true)
        if ([string]::IsNullOrWhiteSpace($this.inputs.Name)) {
            $this.App.GoBackOr('main')
            return
        }

        # Step 2: Description
        $this.inputs.Description = $this.ReadLineAt(16, ($this.rowStart + 1), $false)
        if ($null -eq $this.inputs.Description) {
            $this.App.GoBackOr('main')
            return
        }
        $this.DrawForm(2)
        Draw-ConsoleUIProjectFormValues -app $this.App -RowStart $this.rowStart -Inputs $this.inputs

        # Step 3: ID1
        $this.inputs.ID1 = $this.ReadLineAt(9, ($this.rowStart + 2), $false)
        if ($null -eq $this.inputs.ID1) {
            $this.App.GoBackOr('main')
            return
        }
        $this.DrawForm(3)
        Draw-ConsoleUIProjectFormValues -app $this.App -RowStart $this.rowStart -Inputs $this.inputs

        # Step 4: ID2
        $this.inputs.ID2 = $this.ReadLineAt(9, ($this.rowStart + 3), $false)
        if ($null -eq $this.inputs.ID2) {
            $this.App.GoBackOr('main')
            return
        }
        $this.DrawForm(4)
        Draw-ConsoleUIProjectFormValues -app $this.App -RowStart $this.rowStart -Inputs $this.inputs

        # Step 5: ProjFolder (with F2 picker)
        $this.inputs.ProjFolder = Select-ConsoleUIPathAt -app $this.App -Hint "Project Folder (Enter to pick)" -Col 20 -Row ($this.rowStart + 4) -StartPath $this.defaultRoot -DirectoriesOnly:$true
        $this.DrawForm(5)
        Draw-ConsoleUIProjectFormValues -app $this.App -RowStart $this.rowStart -Inputs $this.inputs

        # Step 6: CAAName (with F2 picker)
        $this.inputs.CAAName = Select-ConsoleUIPathAt -app $this.App -Hint "CAA (Enter to pick)" -Col 14 -Row ($this.rowStart + 5) -StartPath $this.defaultRoot -DirectoriesOnly:$false
        $this.DrawForm(6)
        Draw-ConsoleUIProjectFormValues -app $this.App -RowStart $this.rowStart -Inputs $this.inputs

        # Step 7: RequestName (with F2 picker)
        $this.inputs.RequestName = Select-ConsoleUIPathAt -app $this.App -Hint "Request (Enter to pick)" -Col 17 -Row ($this.rowStart + 6) -StartPath $this.defaultRoot -DirectoriesOnly:$false
        $this.DrawForm(7)
        Draw-ConsoleUIProjectFormValues -app $this.App -RowStart $this.rowStart -Inputs $this.inputs

        # Step 8: T2020 (with F2 picker)
        $this.inputs.T2020 = Select-ConsoleUIPathAt -app $this.App -Hint "T2020 (Enter to pick)" -Col 11 -Row ($this.rowStart + 7) -StartPath $this.defaultRoot -DirectoriesOnly:$false
        $this.DrawForm(8)
        Draw-ConsoleUIProjectFormValues -app $this.App -RowStart $this.rowStart -Inputs $this.inputs

        # Step 9: AssignedDate
        $this.inputs.AssignedDate = $this.ReadLineAt(32, ($this.rowStart + 8), $false)
        if ($null -eq $this.inputs.AssignedDate) {
            $this.App.GoBackOr('main')
            return
        }

        # Step 10: DueDate
        $this.inputs.DueDate = $this.ReadLineAt(27, ($this.rowStart + 9), $false)
        if ($null -eq $this.inputs.DueDate) {
            $this.App.GoBackOr('main')
            return
        }

        # Step 11: BFDate
        $this.inputs.BFDate = $this.ReadLineAt(26, ($this.rowStart + 10), $false)
        if ($null -eq $this.inputs.BFDate) {
            $this.App.GoBackOr('main')
            return
        }

        # Normalize dates
        foreach ($pair in @(@{k='AssignedDate'; v=$this.inputs.AssignedDate}, @{k='DueDate'; v=$this.inputs.DueDate}, @{k='BFDate'; v=$this.inputs.BFDate})) {
            $norm = Normalize-ConsoleUIDate $pair.v
            if ($null -eq $norm -and -not [string]::IsNullOrWhiteSpace([string]$pair.v)) {
                Show-InfoMessage -Message ("Invalid {0}. Use yyyymmdd, mmdd, +/-N, today/tomorrow/yesterday, or yyyy-MM-dd." -f $pair.k) -Title "Validation" -Color "Red"
                $this.App.GoBackOr('main')
                return
            }
            switch ($pair.k) {
                'AssignedDate' { $this.inputs.AssignedDate = $norm }
                'DueDate'      { $this.inputs.DueDate = $norm }
                'BFDate'       { $this.inputs.BFDate = $norm }
            }
        }

        # Create the project
        try {
            $data = Get-PmcAllData
            if (-not $data.projects) { $data.projects = @() }

            # Normalize any legacy string entries to objects
            try {
                $normalized = @()
                foreach ($p in @($data.projects)) {
                    if ($p -is [string]) {
                        $normalized += [pscustomobject]@{
                            id = [guid]::NewGuid().ToString()
                            name = $p
                            description = ''
                            created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                            status = 'active'
                            tags = @()
                        }
                    } else {
                        $normalized += $p
                    }
                }
                $data.projects = $normalized
            } catch {}

            # Duplicate project name check
            $exists = @($data.projects | Where-Object { $_.PSObject.Properties['name'] -and $_.name -eq $this.inputs.Name })
            if ($exists.Count -gt 0) {
                Show-InfoMessage -Message ("Project '{0}' already exists" -f $this.inputs.Name) -Title "Error" -Color "Red"
                $this.App.GoBackOr('main')
                return
            }

            # Build project object with all extended fields
            $newProject = [pscustomobject]@{
                id = [guid]::NewGuid().ToString()
                name = $this.inputs.Name
                description = $this.inputs.Description
                ID1 = $this.inputs.ID1
                ID2 = $this.inputs.ID2
                ProjFolder = $this.inputs.ProjFolder
                AssignedDate = $this.inputs.AssignedDate
                DueDate = $this.inputs.DueDate
                BFDate = $this.inputs.BFDate
                CAAName = $this.inputs.CAAName
                RequestName = $this.inputs.RequestName
                T2020 = $this.inputs.T2020
                icon = ''
                color = 'Gray'
                sortOrder = 0
                aliases = @()
                isArchived = $false
                created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                status = 'active'
                tags = @()
            }

            $data.projects += $newProject
            Set-PmcAllData $data
            Show-InfoMessage -Message ("Project '{0}' created" -f $this.inputs.Name) -Title "Success" -Color "Green"
        } catch {
            Show-InfoMessage -Message ("Failed to create project: {0}" -f $_) -Title "Error" -Color "Red"
        }

        $this.App.GoBackOr('projectlist')
        $this.App.DrawLayout()
    }

    [bool] HandleKey([System.ConsoleKeyInfo]$key) {
        # Wizard handles its own keys during RunWizard()
        return $true
    }

    [void] Draw() {
        # Drawing happens in DrawForm() during wizard steps
    }
}

Export-ModuleMember -Variable * -Function *
