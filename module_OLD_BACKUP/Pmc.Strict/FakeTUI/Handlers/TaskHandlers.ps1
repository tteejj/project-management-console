# Task operation handlers for FakeTUI
# Handles: Copy, Move, Find, Priority, Postpone, Note operations

function Invoke-TaskCopyHandler {
    param($app)

    # Get task ID via input form
    $input = Show-InputForm -Title "Copy Task" -Fields @(
        @{Name='id'; Label='Task ID to copy'; Required=$true; Type='text'}
    )

    if (-not $input) {
        $app.currentView = 'main'
        $app.DrawLayout()
        return
    }

    $id = try { [int]$input['id'] } catch { 0 }

    try {
        $data = Get-PmcAllData
        $task = $data.tasks | Where-Object { $_.id -eq $id }

        if (-not $task) {
            Show-InfoMessage -Message "Task #$id not found!" -Title "Error" -Color "Red"
        } else {
            # Get available projects for selection
            $projectList = @('(none)', 'inbox') + @($data.projects | ForEach-Object { $_.name } | Where-Object { $_ -and $_ -ne 'inbox' } | Sort-Object)

            # Ask if user wants to change project
            $changeProject = Show-ConfirmDialog -Message "Change project for the copy?" -Title "Copy Task"

            $newProject = $task.project
            if ($changeProject) {
                $selected = Show-SelectList -Title "Select New Project" -Options $projectList -DefaultValue $task.project
                if ($selected) {
                    $newProject = if ($selected -eq '(none)') { $null } else { $selected }
                }
            }

            # Copy task with new ID
            $newTask = $task.PSObject.Copy()
            $newTask.id = (Get-PmcNextTaskId)
            $newTask.project = $newProject

            # Remove completed status and timestamp from copy
            $newTask.status = 'active'
            if ($newTask.PSObject.Properties['completedAt']) {
                $newTask.PSObject.Properties.Remove('completedAt')
            }

            $data.tasks += $newTask
            Save-PmcData -Data $data -Action "Copied task #$id to #$($newTask.id)"

            Show-InfoMessage -Message "Task copied! New ID: #$($newTask.id)" -Title "Success" -Color "Green"
        }
    } catch {
        Show-InfoMessage -Message "Error: $_" -Title "Error" -Color "Red"
    }

    $app.currentView = 'main'
    $app.DrawLayout()
}

function Invoke-TaskMoveHandler {
    param($app)

    # Get task ID via input form
    $input = Show-InputForm -Title "Move Task" -Fields @(
        @{Name='id'; Label='Task ID to move'; Required=$true; Type='text'}
    )

    if (-not $input) {
        $app.currentView = 'main'
        $app.DrawLayout()
        return
    }

    $id = try { [int]$input['id'] } catch { 0 }

    try {
        $data = Get-PmcAllData
        $task = $data.tasks | Where-Object { $_.id -eq $id }

        if (-not $task) {
            Show-InfoMessage -Message "Task #$id not found!" -Title "Error" -Color "Red"
        } else {
            # Get available projects for selection
            $projectList = @('(none)', 'inbox') + @($data.projects | ForEach-Object { $_.name } | Where-Object { $_ -and $_ -ne 'inbox' } | Sort-Object)

            # Show project selection
            $selected = Show-SelectList -Title "Select New Project" -Options $projectList -DefaultValue $task.project

            if ($selected) {
                $oldProject = $task.project
                $task.project = if ($selected -eq '(none)') { $null } else { $selected }

                Save-PmcData -Data $data -Action "Moved task #$id from '$oldProject' to '$selected'"

                Show-InfoMessage -Message "Task moved to: $selected" -Title "Success" -Color "Green"
            }
        }
    } catch {
        Show-InfoMessage -Message "Error: $_" -Title "Error" -Color "Red"
    }

    $app.currentView = 'main'
    $app.DrawLayout()
}

function Invoke-TaskFindHandler {
    param($app)

    $app.terminal.Clear()
    $app.menuSystem.DrawMenuBar()
    $title = " Find Tasks "
    $titleX = ($app.terminal.Width - $title.Length) / 2
    $app.terminal.WriteAtColor([int]$titleX, 3, $title, [PmcVT100]::BgBlue(), [PmcVT100]::White())

    $app.terminal.WriteAtColor(4, 6, "Search text:", [PmcVT100]::Yellow(), "")

    $app.terminal.FillArea(0, $app.terminal.Height - 1, $app.terminal.Width, 1, ' ')
    $app.terminal.WriteAt(2, $app.terminal.Height - 1, "Enter search term | Esc=Cancel")

    $app.terminal.WriteAt(18, 6, "")
    [Console]::SetCursorPosition(18, 6)
    $searchTerm = [Console]::ReadLine()

    if ([string]::IsNullOrWhiteSpace($searchTerm)) {
        $app.currentView = 'main'
        $app.DrawLayout()
        return
    }

    try {
        $data = Get-PmcAllData
        $found = @($data.tasks | Where-Object {
            $_.text -like "*$searchTerm*" -or
            ($_.PSObject.Properties['description'] -and $_.description -like "*$searchTerm*") -or
            ($_.PSObject.Properties['tags'] -and ($_.tags -join ' ') -like "*$searchTerm*")
        })

        if ($found.Count -eq 0) {
            $app.terminal.WriteAtColor(4, 9, "No tasks found matching '$searchTerm'", [PmcVT100]::Yellow(), "")
        } else {
            $app.terminal.WriteAtColor(4, 9, "Found $($found.Count) tasks:", [PmcVT100]::Green(), "")

            $y = 11
            foreach ($task in ($found | Select-Object -First 20)) {
                if ($y -ge $app.terminal.Height - 3) { break }

                $status = if ($task.status -eq 'completed') { '✓' } else { ' ' }
                $pri = switch ($task.priority) {
                    'high' { '🔴' }
                    'medium' { '🟡' }
                    default { '⚪' }
                }

                $text = "[$status] #$($task.id) $pri $($task.text)"
                $app.terminal.WriteAt(4, $y, $text.Substring(0, [Math]::Min($app.terminal.Width - 6, $text.Length)))
                $y++
            }

            if ($found.Count -gt 20) {
                $app.terminal.WriteAtColor(4, $y, "... and $($found.Count - 20) more", [PmcVT100]::Cyan(), "")
            }
        }
    } catch {
        $app.terminal.WriteAtColor(4, 9, "Error: $_", [PmcVT100]::Red(), "")
    }

    $app.terminal.FillArea(0, $app.terminal.Height - 1, $app.terminal.Width, 1, ' ')
    $app.terminal.WriteAt(2, $app.terminal.Height - 1, "Press any key to return")
    [Console]::ReadKey($true) | Out-Null

    $app.currentView = 'main'
    $app.DrawLayout()
}

function Invoke-TaskPriorityHandler {
    param($app)

    # Get task ID and priority via input form
    $input = Show-InputForm -Title "Set Task Priority" -Fields @(
        @{Name='id'; Label='Task ID'; Required=$true; Type='text'}
        @{Name='priority'; Label='Priority'; Required=$true; Type='select'; Options=@('high', 'medium', 'low')}
    )

    if (-not $input) {
        $app.currentView = 'main'
        $app.DrawLayout()
        return
    }

    $id = try { [int]$input['id'] } catch { 0 }
    $priority = $input['priority']

    try {
        $data = Get-PmcAllData
        $task = $data.tasks | Where-Object { $_.id -eq $id }

        if (-not $task) {
            Show-InfoMessage -Message "Task #$id not found!" -Title "Error" -Color "Red"
        } else {
            $task.priority = $priority
            Save-PmcData -Data $data -Action "Set priority of task #$id to $priority"

            Show-InfoMessage -Message "Priority updated to: $priority" -Title "Success" -Color "Green"
        }
    } catch {
        Show-InfoMessage -Message "Error: $_" -Title "Error" -Color "Red"
    }

    $app.currentView = 'main'
    $app.DrawLayout()
}

function Invoke-TaskPostponeHandler {
    param($app)

    $input = Show-InputForm -Title "Postpone Task" -Fields @(
        @{Name='id'; Label='Task ID'; Required=$true; Type='text'}
        @{Name='days'; Label='Postpone by days'; Required=$true; Type='text'}
    )

    if (-not $input) {
        $app.currentView = 'main'
        $app.DrawLayout()
        return
    }

    $id = try { [int]$input['id'] } catch { 0 }
    $days = try { [int]$input['days'] } catch { 1 }

    try {
        $data = Get-PmcAllData
        $task = $data.tasks | Where-Object { $_.id -eq $id }

        if (-not $task) {
            Show-InfoMessage -Message "Task #$id not found!" -Title "Error" -Color "Red"
        } else {
            if ($task.PSObject.Properties['dueDate'] -and $task.dueDate) {
                $currentDue = [datetime]$task.dueDate
                $newDue = $currentDue.AddDays($days)
                $task.dueDate = $newDue.ToString("yyyy-MM-dd")
            } else {
                # No due date, set it to today + days
                $task.dueDate = (Get-Date).AddDays($days).ToString("yyyy-MM-dd")
            }

            Save-PmcData -Data $data -Action "Postponed task #$id by $days days"
            Show-InfoMessage -Message "Task postponed! New due: $($task.dueDate)" -Title "Success" -Color "Green"
        }
    } catch {
        Show-InfoMessage -Message "Error: $_" -Title "Error" -Color "Red"
    }

    $app.currentView = 'main'
    $app.DrawLayout()
}

function Invoke-TaskNoteHandler {
    param($app)

    $input = Show-InputForm -Title "Add Task Note" -Fields @(
        @{Name='id'; Label='Task ID'; Required=$true; Type='text'}
        @{Name='note'; Label='Note'; Required=$true; Type='text'}
    )

    if (-not $input) {
        $app.currentView = 'main'
        $app.DrawLayout()
        return
    }

    $id = try { [int]$input['id'] } catch { 0 }
    $note = $input['note']

    try {
        $data = Get-PmcAllData
        $task = $data.tasks | Where-Object { $_.id -eq $id }

        if (-not $task) {
            Show-InfoMessage -Message "Task #$id not found!" -Title "Error" -Color "Red"
        } else {
            # Add to activities array
            if (-not $task.PSObject.Properties['activities']) {
                $task | Add-Member -MemberType NoteProperty -Name 'activities' -Value @()
            }

            $activity = @{
                timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                type = 'note'
                text = $note
            }

            $task.activities += $activity
            Save-PmcData -Data $data -Action "Added note to task #$id"
            Show-InfoMessage -Message "Note added!" -Title "Success" -Color "Green"
        }
    } catch {
        Show-InfoMessage -Message "Error: $_" -Title "Error" -Color "Red"
    }

    $app.currentView = 'main'
    $app.DrawLayout()
}

