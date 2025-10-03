# Task List Screen - Main PMC interface
# Shows tasks with filtering, sorting, and basic operations

class PmcTaskListScreen {
    [object]$Terminal
    [object]$MenuSystem
    [object]$Data
    [array]$Tasks
    [array]$FilteredTasks
    [int]$SelectedIndex = 0
    [int]$ScrollOffset = 0
    [string]$FilterMode = 'all'  # all, active, completed, project
    [string]$FilterValue = ''
    [string]$SortMode = 'id'     # id, priority, status, project, created
    [bool]$NeedsRefresh = $true

    PmcTaskListScreen([object]$terminal, [object]$menuSystem) {
        $this.Terminal = $terminal
        $this.MenuSystem = $menuSystem
        $this.LoadData()
    }

    [void] LoadData() {
        try {
            # Use Get-PmcAllData since Get-PmcData export is broken
            $this.Data = Get-PmcAllData
            $this.Tasks = @($this.Data.tasks | Where-Object { $_ -ne $null })
            $this.ApplyFilters()
            $this.NeedsRefresh = $true
        } catch {
            $this.Tasks = @()
            $this.FilteredTasks = @()
        }
    }

    [void] ApplyFilters() {
        $filtered = $this.Tasks

        switch ($this.FilterMode) {
            'active' { $filtered = @($filtered | Where-Object { $_.status -ne 'completed' }) }
            'completed' { $filtered = @($filtered | Where-Object { $_.status -eq 'completed' }) }
            'project' {
                if ($this.FilterValue) {
                    $filtered = @($filtered | Where-Object { $_.project -eq $this.FilterValue })
                }
            }
        }

        # Sort tasks
        switch ($this.SortMode) {
            'id' { $filtered = @($filtered | Sort-Object { [int]$_.id }) }
            'priority' { $filtered = @($filtered | Sort-Object {
                switch ($_.priority) {
                    'high' { 1 }
                    'medium' { 2 }
                    'low' { 3 }
                    default { 4 }
                }
            }) }
            'status' { $filtered = @($filtered | Sort-Object status) }
            'project' { $filtered = @($filtered | Sort-Object project) }
            'created' { $filtered = @($filtered | Sort-Object created) }
        }

        $this.FilteredTasks = $filtered

        # Adjust selection if needed
        if ($this.SelectedIndex -ge $this.FilteredTasks.Count) {
            $this.SelectedIndex = [Math]::Max(0, $this.FilteredTasks.Count - 1)
        }
    }

    [void] Draw() {
        if (-not $this.NeedsRefresh) { return }

        $width = [Console]::WindowWidth
        $height = [Console]::WindowHeight

        # Clear main area (leave menu bar and status bar)
        for ($y = 2; $y -lt ($height - 2); $y++) {
            $this.Terminal.WriteAt(0, $y, (' ' * $width))
        }

        # Draw title and filter info
        $title = "Tasks ($($this.FilteredTasks.Count) of $($this.Tasks.Count))"
        if ($this.FilterMode -ne 'all') {
            $title += " - Filter: $($this.FilterMode)"
            if ($this.FilterValue) { $title += " ($($this.FilterValue))" }
        }
        $title += " - Sort: $($this.SortMode)"

        $this.Terminal.WriteAt(2, 2, $title)

        # Draw column headers
        $headerY = 4
        $this.Terminal.WriteAt(2, $headerY, "ID")
        $this.Terminal.WriteAt(6, $headerY, "Pri")
        $this.Terminal.WriteAt(10, $headerY, "Status")
        $this.Terminal.WriteAt(20, $headerY, "Project")
        $this.Terminal.WriteAt(32, $headerY, "Task")

        # Draw separator
        $this.Terminal.WriteAt(0, $headerY + 1, ('─' * $width))

        # Draw tasks
        $startY = $headerY + 2
        $visibleRows = $height - $startY - 2  # Leave space for status bar

        for ($i = 0; $i -lt $visibleRows -and ($i + $this.ScrollOffset) -lt $this.FilteredTasks.Count; $i++) {
            $taskIndex = $i + $this.ScrollOffset
            $task = $this.FilteredTasks[$taskIndex]
            $y = $startY + $i

            # Highlight selected row
            $isSelected = ($taskIndex -eq $this.SelectedIndex)
            if ($isSelected) {
                $this.Terminal.WriteAt(0, $y, (' ' * $width))
                $this.Terminal.WriteAt(0, $y, "`e[7m") # Reverse video
            }

            # Format task data
            $id = if ($task.id) { $task.id.ToString().PadRight(3) } else { "   " }
            $priority = switch ($task.priority) {
                'high' { "`e[31mH`e[0m" }    # Red
                'medium' { "`e[33mM`e[0m" }  # Yellow
                'low' { "`e[32mL`e[0m" }     # Green
                default { " " }
            }
            $status = switch ($task.status) {
                'active' { "`e[32m●`e[0m" }      # Green dot
                'completed' { "`e[90m✓`e[0m" }   # Gray checkmark
                'waiting' { "`e[33m⏸`e[0m" }     # Yellow pause
                default { " " }
            }
            $project = if ($task.project) { $task.project.ToString().PadRight(10).Substring(0, 10) } else { "          " }
            $text = if ($task.text) { $task.text.ToString() } else { "" }
            if ($text.Length -gt 40) { $text = $text.Substring(0, 37) + "..." }

            # Draw the row
            $this.Terminal.WriteAt(2, $y, $id)
            $this.Terminal.WriteAt(6, $y, $priority)
            $this.Terminal.WriteAt(10, $y, $status)
            $this.Terminal.WriteAt(20, $y, $project)
            $this.Terminal.WriteAt(32, $y, $text)

            if ($isSelected) {
                $this.Terminal.WriteAt(0, $y, "`e[0m") # Reset formatting
            }
        }

        # Draw status bar
        $statusY = $height - 1
        $selectedTask = if ($this.SelectedIndex -lt $this.FilteredTasks.Count) { $this.FilteredTasks[$this.SelectedIndex] } else { $null }
        $statusText = ""
        if ($selectedTask) {
            $statusText = "Task #$($selectedTask.id): $($selectedTask.text)"
            if ($selectedTask.notes -and $selectedTask.notes.Count -gt 0) {
                $statusText += " | Notes: $($selectedTask.notes.Count)"
            }
        }
        $statusText += " | F1:Help F2:Filter F3:Sort F5:Refresh Enter:Edit"

        $this.Terminal.WriteAt(0, $statusY, (' ' * $width))
        $this.Terminal.WriteAt(0, $statusY, $statusText.Substring(0, [Math]::Min($statusText.Length, $width)))

        $this.NeedsRefresh = $false
    }

    [bool] HandleKey([System.ConsoleKeyInfo]$key) {
        $handled = $true

        switch ($key.Key) {
            'UpArrow' {
                if ($this.SelectedIndex -gt 0) {
                    $this.SelectedIndex--
                    if ($this.SelectedIndex -lt $this.ScrollOffset) {
                        $this.ScrollOffset = $this.SelectedIndex
                    }
                    $this.NeedsRefresh = $true
                }
            }
            'DownArrow' {
                if ($this.SelectedIndex -lt ($this.FilteredTasks.Count - 1)) {
                    $this.SelectedIndex++
                    $visibleRows = [Console]::WindowHeight - 8
                    if ($this.SelectedIndex -ge ($this.ScrollOffset + $visibleRows)) {
                        $this.ScrollOffset = $this.SelectedIndex - $visibleRows + 1
                    }
                    $this.NeedsRefresh = $true
                }
            }
            'PageUp' {
                $pageSize = [Console]::WindowHeight - 8
                $this.SelectedIndex = [Math]::Max(0, $this.SelectedIndex - $pageSize)
                $this.ScrollOffset = [Math]::Max(0, $this.ScrollOffset - $pageSize)
                $this.NeedsRefresh = $true
            }
            'PageDown' {
                $pageSize = [Console]::WindowHeight - 8
                $this.SelectedIndex = [Math]::Min($this.FilteredTasks.Count - 1, $this.SelectedIndex + $pageSize)
                $visibleRows = [Console]::WindowHeight - 8
                if ($this.SelectedIndex -ge ($this.ScrollOffset + $visibleRows)) {
                    $this.ScrollOffset = $this.SelectedIndex - $visibleRows + 1
                }
                $this.NeedsRefresh = $true
            }
            'Home' {
                $this.SelectedIndex = 0
                $this.ScrollOffset = 0
                $this.NeedsRefresh = $true
            }
            'End' {
                $this.SelectedIndex = [Math]::Max(0, $this.FilteredTasks.Count - 1)
                $visibleRows = [Console]::WindowHeight - 8
                $this.ScrollOffset = [Math]::Max(0, $this.FilteredTasks.Count - $visibleRows)
                $this.NeedsRefresh = $true
            }
            'Enter' {
                if ($this.SelectedIndex -lt $this.FilteredTasks.Count) {
                    $this.EditTask($this.FilteredTasks[$this.SelectedIndex])
                }
            }
            'F2' {
                $this.ShowFilterDialog()
            }
            'F3' {
                $this.ShowSortDialog()
            }
            'F5' {
                $this.LoadData()
            }
            'Delete' {
                if ($this.SelectedIndex -lt $this.FilteredTasks.Count) {
                    $this.DeleteTask($this.FilteredTasks[$this.SelectedIndex])
                }
            }
            'Insert' {
                $this.AddNewTask()
            }
            default {
                $handled = $false
            }
        }

        return $handled
    }

    [void] EditTask([object]$task) {
        # Simple inline edit for now
        $height = [Console]::WindowHeight
        $editY = $height - 3

        # Clear edit area
        $this.Terminal.WriteAt(0, $editY, (' ' * [Console]::WindowWidth))
        $this.Terminal.WriteAt(0, $editY, "Edit task: ")

        # This would open a proper edit dialog in a full implementation
        Write-Host "Edit task functionality would go here for task #$($task.id)"
    }

    [void] AddNewTask() {
        # Simple add dialog
        Write-Host "Add new task functionality would go here"
    }

    [void] DeleteTask([object]$task) {
        # Confirmation dialog would go here
        Write-Host "Delete task #$($task.id) functionality would go here"
    }

    [void] ShowFilterDialog() {
        # Quick filter toggle for now
        $filters = @('all', 'active', 'completed')
        $currentIndex = $filters.IndexOf($this.FilterMode)
        $nextIndex = ($currentIndex + 1) % $filters.Count
        $this.FilterMode = $filters[$nextIndex]
        $this.ApplyFilters()
        $this.NeedsRefresh = $true
    }

    [void] ShowSortDialog() {
        # Quick sort toggle
        $sorts = @('id', 'priority', 'status', 'project', 'created')
        $currentIndex = $sorts.IndexOf($this.SortMode)
        $nextIndex = ($currentIndex + 1) % $sorts.Count
        $this.SortMode = $sorts[$nextIndex]
        $this.ApplyFilters()
        $this.NeedsRefresh = $true
    }
}

Export-ModuleMember -Function *