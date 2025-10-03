# Project List Screen - Project management interface
# Shows projects with task counts, status, and basic operations

class PmcProjectListScreen {
    [object]$Terminal
    [object]$MenuSystem
    [object]$Data
    [array]$Projects
    [array]$FilteredProjects
    [int]$SelectedIndex = 0
    [int]$ScrollOffset = 0
    [string]$FilterMode = 'all'  # all, active, completed, archived
    [string]$SortMode = 'name'   # name, status, created, tasks
    [bool]$NeedsRefresh = $true

    PmcProjectListScreen([object]$terminal, [object]$menuSystem) {
        $this.Terminal = $terminal
        $this.MenuSystem = $menuSystem
        $this.LoadData()
    }

    [void] LoadData() {
        try {
            $this.Data = Get-PmcData
            $this.Projects = @($this.Data.projects | Where-Object { $_ -ne $null })

            # Add task counts to projects
            foreach ($project in $this.Projects) {
                $taskCount = @($this.Data.tasks | Where-Object { $_.project -eq $project.name }).Count
                $activeTaskCount = @($this.Data.tasks | Where-Object { $_.project -eq $project.name -and $_.status -ne 'completed' }).Count
                $project | Add-Member -NotePropertyName 'taskCount' -NotePropertyValue $taskCount -Force
                $project | Add-Member -NotePropertyName 'activeTaskCount' -NotePropertyValue $activeTaskCount -Force
            }

            $this.ApplyFilters()
            $this.NeedsRefresh = $true
        } catch {
            $this.Projects = @()
            $this.FilteredProjects = @()
        }
    }

    [void] ApplyFilters() {
        $filtered = $this.Projects

        switch ($this.FilterMode) {
            'active' { $filtered = @($filtered | Where-Object { $_.status -ne 'completed' -and $_.status -ne 'archived' }) }
            'completed' { $filtered = @($filtered | Where-Object { $_.status -eq 'completed' }) }
            'archived' { $filtered = @($filtered | Where-Object { $_.status -eq 'archived' }) }
        }

        # Sort projects
        switch ($this.SortMode) {
            'name' { $filtered = @($filtered | Sort-Object name) }
            'status' { $filtered = @($filtered | Sort-Object status) }
            'created' { $filtered = @($filtered | Sort-Object created -Descending) }
            'tasks' { $filtered = @($filtered | Sort-Object taskCount -Descending) }
        }

        $this.FilteredProjects = $filtered

        # Adjust selection if needed
        if ($this.SelectedIndex -ge $this.FilteredProjects.Count) {
            $this.SelectedIndex = [Math]::Max(0, $this.FilteredProjects.Count - 1)
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
        $title = "Projects ($($this.FilteredProjects.Count) of $($this.Projects.Count))"
        if ($this.FilterMode -ne 'all') {
            $title += " - Filter: $($this.FilterMode)"
        }
        $title += " - Sort: $($this.SortMode)"

        $this.Terminal.WriteAt(2, 2, $title)

        # Draw column headers
        $headerY = 4
        $this.Terminal.WriteAt(2, $headerY, "Project Name")
        $this.Terminal.WriteAt(25, $headerY, "Status")
        $this.Terminal.WriteAt(35, $headerY, "Tasks")
        $this.Terminal.WriteAt(45, $headerY, "Active")
        $this.Terminal.WriteAt(55, $headerY, "Created")

        # Draw separator
        $this.Terminal.WriteAt(0, $headerY + 1, ('─' * $width))

        # Draw projects
        $startY = $headerY + 2
        $visibleRows = $height - $startY - 2  # Leave space for status bar

        for ($i = 0; $i -lt $visibleRows -and ($i + $this.ScrollOffset) -lt $this.FilteredProjects.Count; $i++) {
            $projectIndex = $i + $this.ScrollOffset
            $project = $this.FilteredProjects[$projectIndex]
            $y = $startY + $i

            # Highlight selected row
            $isSelected = ($projectIndex -eq $this.SelectedIndex)
            if ($isSelected) {
                $this.Terminal.WriteAt(0, $y, (' ' * $width))
                $this.Terminal.WriteAt(0, $y, "`e[7m") # Reverse video
            }

            # Format project data
            $name = if ($project.name) { $project.name.ToString().PadRight(20).Substring(0, 20) } else { "                    " }

            $status = switch ($project.status) {
                'active' { "`e[32mActive`e[0m" }       # Green
                'completed' { "`e[90mCompleted`e[0m" } # Gray
                'archived' { "`e[90mArchived`e[0m" }   # Gray
                'on-hold' { "`e[33mOn-Hold`e[0m" }     # Yellow
                default { $project.status }
            }

            $taskCount = if ($project.taskCount) { $project.taskCount.ToString().PadLeft(3) } else { "  0" }
            $activeCount = if ($project.activeTaskCount) { $project.activeTaskCount.ToString().PadLeft(3) } else { "  0" }

            $created = if ($project.created) {
                try {
                    ([DateTime]$project.created).ToString('yyyy-MM-dd')
                } catch {
                    $project.created.ToString().Substring(0, [Math]::Min(10, $project.created.ToString().Length))
                }
            } else {
                "          "
            }

            # Draw the row
            $this.Terminal.WriteAt(2, $y, $name)
            $this.Terminal.WriteAt(25, $y, $status)
            $this.Terminal.WriteAt(45, $y, $taskCount)
            $this.Terminal.WriteAt(52, $y, $activeCount)
            $this.Terminal.WriteAt(58, $y, $created)

            if ($isSelected) {
                $this.Terminal.WriteAt(0, $y, "`e[0m") # Reset formatting
            }
        }

        # Draw status bar
        $statusY = $height - 1
        $selectedProject = if ($this.SelectedIndex -lt $this.FilteredProjects.Count) { $this.FilteredProjects[$this.SelectedIndex] } else { $null }
        $statusText = ""
        if ($selectedProject) {
            $statusText = "Project: $($selectedProject.name)"
            if ($selectedProject.description) {
                $statusText += " - $($selectedProject.description)"
            }
            $statusText += " | $($selectedProject.taskCount) total tasks, $($selectedProject.activeTaskCount) active"
        }
        $statusText += " | F1:Help F2:Filter F3:Sort F5:Refresh Enter:View Tasks"

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
                if ($this.SelectedIndex -lt ($this.FilteredProjects.Count - 1)) {
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
                $this.SelectedIndex = [Math]::Min($this.FilteredProjects.Count - 1, $this.SelectedIndex + $pageSize)
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
                $this.SelectedIndex = [Math]::Max(0, $this.FilteredProjects.Count - 1)
                $visibleRows = [Console]::WindowHeight - 8
                $this.ScrollOffset = [Math]::Max(0, $this.FilteredProjects.Count - $visibleRows)
                $this.NeedsRefresh = $true
            }
            'Enter' {
                if ($this.SelectedIndex -lt $this.FilteredProjects.Count) {
                    $this.ViewProjectTasks($this.FilteredProjects[$this.SelectedIndex])
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
                if ($this.SelectedIndex -lt $this.FilteredProjects.Count) {
                    $this.DeleteProject($this.FilteredProjects[$this.SelectedIndex])
                }
            }
            'Insert' {
                $this.AddNewProject()
            }
            default {
                $handled = $false
            }
        }

        return $handled
    }

    [void] ViewProjectTasks([object]$project) {
        # Switch to task list screen filtered by this project
        Write-Host "View tasks for project '$($project.name)' - would switch to task screen with project filter"
    }

    [void] AddNewProject() {
        # Simple add dialog
        Write-Host "Add new project functionality would go here"
    }

    [void] DeleteProject([object]$project) {
        # Confirmation dialog would go here
        Write-Host "Delete project '$($project.name)' functionality would go here"
    }

    [void] ShowFilterDialog() {
        # Quick filter toggle for now
        $filters = @('all', 'active', 'completed', 'archived')
        $currentIndex = $filters.IndexOf($this.FilterMode)
        $nextIndex = ($currentIndex + 1) % $filters.Count
        $this.FilterMode = $filters[$nextIndex]
        $this.ApplyFilters()
        $this.NeedsRefresh = $true
    }

    [void] ShowSortDialog() {
        # Quick sort toggle
        $sorts = @('name', 'status', 'created', 'tasks')
        $currentIndex = $sorts.IndexOf($this.SortMode)
        $nextIndex = ($currentIndex + 1) % $sorts.Count
        $this.SortMode = $sorts[$nextIndex]
        $this.ApplyFilters()
        $this.NeedsRefresh = $true
    }
}

Export-ModuleMember -Function *