# Time.ps1 - Time tracking and timer functions

function Add-PmcTimeEntry {
    param([PmcCommandContext]$Context)

    try {
        $allData = Get-PmcAllData

        # Default values for new time entry
        $entry = @{
            id = Get-PmcNextTimeId $allData
            project = $allData.currentContext
            date = (Get-Date).ToString('yyyy-MM-dd')
            minutes = 0
            description = ""
            created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        }

        # Parse free text for time entry details
        if ($Context.FreeText.Count -gt 0) {
            $text = ($Context.FreeText -join ' ').Trim()

            # Parse minutes from text (look for numbers followed by 'm' or 'min')
            if ($text -match '(\d+)m(?:in)?') {
                $entry.minutes = [int]$matches[1]
                $text = $text -replace '\d+m(?:in)?', ''
            }

            # Parse project from @project syntax
            if ($text -match '@(\w+)') {
                $entry.project = $matches[1]
                $text = $text -replace '@\w+', ''
            }

            # Rest is description
            $entry.description = $text.Trim()
        }

        # Add to time entries
        if (-not $allData.timelogs) { $allData.timelogs = @() }
        $allData.timelogs += $entry

        Set-PmcAllData $allData
        Write-PmcStyled -Style 'Success' -Text "✓ Time entry added: $($entry.minutes)m - $($entry.description)"

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error adding time entry: $_"
    }
}

function Get-PmcTimeReport {
    param([PmcCommandContext]$Context)

    try {
        $allData = Get-PmcAllData
        $timelogs = $allData.timelogs | Where-Object { $_ }

        if (-not $timelogs) {
            Write-PmcStyled -Style 'Info' -Text "No time entries found"
            return
        }

        Show-PmcCustomGrid -Domain 'time' -Data $timelogs -Title 'Time Report' -Interactive

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error generating time report: $_"
    }
}

function Get-PmcTimeList {
    param([PmcCommandContext]$Context)

    try {
        $allData = Get-PmcAllData
        $timelogs = $allData.timelogs | Where-Object { $_ }

        if (-not $timelogs) {
            Write-PmcStyled -Style 'Info' -Text "No time entries found"
            return
        }

        # Filter recent entries (last 30 days)
        $recent = $timelogs | Where-Object {
            [datetime]$_.date -ge (Get-Date).AddDays(-30)
        } | Sort-Object date -Descending

        Show-PmcCustomGrid -Domain 'time' -Data $recent -Title 'Recent Time Entries' -Interactive

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error listing time entries: $_"
    }
}

function Edit-PmcTimeEntry {
    param([PmcCommandContext]$Context)

    if (-not $Context -or $Context.FreeText.Count -eq 0) {
        Write-PmcStyled -Style 'Error' -Text "Usage: time edit <id>"
        return
    }

    $entryId = $Context.FreeText[0]

    try {
        $allData = Get-PmcAllData
        $entry = $allData.timelogs | Where-Object { $_.id -eq $entryId }

        if (-not $entry) {
            Write-PmcStyled -Style 'Error' -Text "Time entry '$entryId' not found"
            return
        }

        Write-PmcStyled -Style 'Info' -Text "Time entry editing not yet implemented"

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error editing time entry: $_"
    }
}

function Remove-PmcTimeEntry {
    param([PmcCommandContext]$Context)

    if (-not $Context -or $Context.FreeText.Count -eq 0) {
        Write-PmcStyled -Style 'Error' -Text "Usage: time delete <id>"
        return
    }

    $entryId = $Context.FreeText[0]

    try {
        $allData = Get-PmcAllData
        $entry = $allData.timelogs | Where-Object { $_.id -eq $entryId }

        if (-not $entry) {
            Write-PmcStyled -Style 'Error' -Text "Time entry '$entryId' not found"
            return
        }

        # Remove from time logs
        $allData.timelogs = $allData.timelogs | Where-Object { $_.id -ne $entryId }

        Set-PmcAllData $allData
        Write-PmcStyled -Style 'Success' -Text "✓ Time entry deleted"

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error deleting time entry: $_"
    }
}

function Start-PmcTimer {
    param([PmcCommandContext]$Context)

    try {
        $project = if ($Context.FreeText.Count -gt 0) {
            $Context.FreeText[0]
        } else {
            $allData = Get-PmcAllData
            $allData.currentContext
        }

        Set-PmcState -Section 'Timer' -Key 'Running' -Value $true
        Set-PmcState -Section 'Timer' -Key 'Project' -Value $project
        Set-PmcState -Section 'Timer' -Key 'StartTime' -Value (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')

        Write-PmcStyled -Style 'Success' -Text "⏱️ Timer started for project: $project"

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error starting timer: $_"
    }
}

function Stop-PmcTimer {
    param([PmcCommandContext]$Context)

    try {
        $running = Get-PmcState -Section 'Timer' -Key 'Running'
        if (-not $running) {
            Write-PmcStyled -Style 'Warning' -Text "No timer is currently running"
            return
        }

        $project = Get-PmcState -Section 'Timer' -Key 'Project'
        $startTime = [datetime](Get-PmcState -Section 'Timer' -Key 'StartTime')
        $endTime = Get-Date
        $minutes = [Math]::Round(($endTime - $startTime).TotalMinutes, 0)

        # Create time entry
        $allData = Get-PmcAllData
        $entry = @{
            id = Get-PmcNextTimeId $allData
            project = $project
            date = $startTime.ToString('yyyy-MM-dd')
            minutes = $minutes
            description = "Timer session"
            created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        }

        if (-not $allData.timelogs) { $allData.timelogs = @() }
        $allData.timelogs += $entry
        Set-PmcAllData $allData

        # Clear timer state
        Set-PmcState -Section 'Timer' -Key 'Running' -Value $false

        Write-PmcStyled -Style 'Success' -Text "⏹️ Timer stopped. Logged $minutes minutes to $project"

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error stopping timer: $_"
    }
}

function Get-PmcTimerStatus {
    param([PmcCommandContext]$Context)

    try {
        $running = Get-PmcState -Section 'Timer' -Key 'Running'

        if (-not $running) {
            Write-PmcStyled -Style 'Info' -Text "⏱️ No timer is currently running"
            return
        }

        $project = Get-PmcState -Section 'Timer' -Key 'Project'
        $startTime = [datetime](Get-PmcState -Section 'Timer' -Key 'StartTime')
        $elapsed = (Get-Date) - $startTime
        $minutes = [Math]::Round($elapsed.TotalMinutes, 0)

        Write-PmcStyled -Style 'Warning' -Text "⏱️ Timer running for $project ($minutes minutes elapsed)"

    } catch {
        Write-PmcStyled -Style 'Error' -Text "Error checking timer status: $_"
    }
}

function Get-PmcNextTimeId {
    param($data)

    if (-not $data.timelogs -or $data.timelogs.Count -eq 0) {
        return "T001"
    }

    $maxId = 0
    foreach ($entry in $data.timelogs) {
        if ($entry.id -match '^T(\d+)$') {
            $num = [int]$matches[1]
            if ($num -gt $maxId) { $maxId = $num }
        }
    }

    return "T{0:000}" -f ($maxId + 1)
}

Export-ModuleMember -Function Add-PmcTimeEntry, Get-PmcTimeReport, Get-PmcTimeList, Edit-PmcTimeEntry, Remove-PmcTimeEntry, Start-PmcTimer, Stop-PmcTimer, Get-PmcTimerStatus