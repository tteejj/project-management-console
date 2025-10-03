# Command Palette - Quick action launcher
# Provides keyboard-driven access to all PMC commands

class PmcCommandPalette {
    [object]$Terminal
    [array]$Commands
    [array]$FilteredCommands
    [string]$SearchText = ''
    [int]$SelectedIndex = 0
    [bool]$IsActive = $false
    [object]$SelectedCommand = $null

    PmcCommandPalette([object]$terminal) {
        $this.Terminal = $terminal
        $this.InitializeCommands()
    }

    [void] InitializeCommands() {
        # Build list of available commands
        $this.Commands = @(
            @{ Name = 'Add Task'; Command = 'add task'; Category = 'Task'; Description = 'Create a new task'; Shortcut = 'Ctrl+N' }
            @{ Name = 'Edit Task'; Command = 'edit task'; Category = 'Task'; Description = 'Edit the selected task'; Shortcut = 'Enter' }
            @{ Name = 'Complete Task'; Command = 'complete task'; Category = 'Task'; Description = 'Mark task as completed'; Shortcut = 'Ctrl+D' }
            @{ Name = 'Delete Task'; Command = 'delete task'; Category = 'Task'; Description = 'Delete the selected task'; Shortcut = 'Del' }
            @{ Name = 'Postpone Task'; Command = 'postpone task'; Category = 'Task'; Description = 'Postpone task to later'; Shortcut = 'Ctrl+P' }
            @{ Name = 'Set Priority High'; Command = 'priority high'; Category = 'Task'; Description = 'Set task priority to high'; Shortcut = '' }
            @{ Name = 'Set Priority Medium'; Command = 'priority medium'; Category = 'Task'; Description = 'Set task priority to medium'; Shortcut = '' }
            @{ Name = 'Set Priority Low'; Command = 'priority low'; Category = 'Task'; Description = 'Set task priority to low'; Shortcut = '' }

            @{ Name = 'Add Project'; Command = 'add project'; Category = 'Project'; Description = 'Create a new project'; Shortcut = '' }
            @{ Name = 'Edit Project'; Command = 'edit project'; Category = 'Project'; Description = 'Edit the selected project'; Shortcut = '' }
            @{ Name = 'Archive Project'; Command = 'archive project'; Category = 'Project'; Description = 'Archive the selected project'; Shortcut = '' }
            @{ Name = 'Project Stats'; Command = 'project stats'; Category = 'Project'; Description = 'Show project statistics'; Shortcut = '' }

            @{ Name = 'Filter Active Tasks'; Command = 'filter active'; Category = 'View'; Description = 'Show only active tasks'; Shortcut = 'F2' }
            @{ Name = 'Filter Completed Tasks'; Command = 'filter completed'; Category = 'View'; Description = 'Show only completed tasks'; Shortcut = '' }
            @{ Name = 'Show All Tasks'; Command = 'filter all'; Category = 'View'; Description = 'Show all tasks'; Shortcut = '' }
            @{ Name = 'Sort by Priority'; Command = 'sort priority'; Category = 'View'; Description = 'Sort tasks by priority'; Shortcut = 'F3' }
            @{ Name = 'Sort by Status'; Command = 'sort status'; Category = 'View'; Description = 'Sort tasks by status'; Shortcut = '' }
            @{ Name = 'Sort by Project'; Command = 'sort project'; Category = 'View'; Description = 'Sort tasks by project'; Shortcut = '' }

            @{ Name = 'Search Tasks'; Command = 'search tasks'; Category = 'Search'; Description = 'Search through tasks'; Shortcut = 'Ctrl+F' }
            @{ Name = 'Find by Tag'; Command = 'find tag'; Category = 'Search'; Description = 'Find tasks by tag'; Shortcut = '' }
            @{ Name = 'Find by Project'; Command = 'find project'; Category = 'Search'; Description = 'Find tasks by project'; Shortcut = '' }

            @{ Name = 'Undo'; Command = 'undo'; Category = 'Edit'; Description = 'Undo last action'; Shortcut = 'Ctrl+Z' }
            @{ Name = 'Redo'; Command = 'redo'; Category = 'Edit'; Description = 'Redo last undone action'; Shortcut = 'Ctrl+Y' }
            @{ Name = 'Backup Data'; Command = 'backup'; Category = 'Edit'; Description = 'Create data backup'; Shortcut = '' }
            @{ Name = 'Clean Completed'; Command = 'clean'; Category = 'Edit'; Description = 'Remove completed tasks'; Shortcut = '' }

            @{ Name = 'Refresh Data'; Command = 'refresh'; Category = 'System'; Description = 'Reload data from disk'; Shortcut = 'F5' }
            @{ Name = 'Switch to Tasks'; Command = 'view tasks'; Category = 'Navigation'; Description = 'Switch to task list view'; Shortcut = 'Alt+T' }
            @{ Name = 'Switch to Projects'; Command = 'view projects'; Category = 'Navigation'; Description = 'Switch to project list view'; Shortcut = 'Alt+P' }
            @{ Name = 'Exit Application'; Command = 'exit'; Category = 'System'; Description = 'Exit PMC FakeTUI'; Shortcut = 'Alt+X' }
        )

        $this.FilterCommands()
    }

    [void] FilterCommands() {
        if ([string]::IsNullOrWhiteSpace($this.SearchText)) {
            $this.FilteredCommands = $this.Commands
        } else {
            $searchLower = $this.SearchText.ToLower()
            $this.FilteredCommands = @($this.Commands | Where-Object {
                $_.Name.ToLower().Contains($searchLower) -or
                $_.Description.ToLower().Contains($searchLower) -or
                $_.Category.ToLower().Contains($searchLower) -or
                $_.Command.ToLower().Contains($searchLower)
            })
        }

        # Reset selection if needed
        if ($this.SelectedIndex -ge $this.FilteredCommands.Count) {
            $this.SelectedIndex = [Math]::Max(0, $this.FilteredCommands.Count - 1)
        }
    }

    [object] Show() {
        $this.IsActive = $true
        $this.SelectedCommand = $null

        # Save current screen state
        $this.SaveScreen()

        try {
            while ($this.IsActive) {
                $this.Draw()
                $key = [Console]::ReadKey($true)
                $this.HandleKey($key)
            }
        } finally {
            # Restore screen
            $this.RestoreScreen()
        }

        return $this.SelectedCommand
    }

    [void] Draw() {
        $width = [Console]::WindowWidth
        $height = [Console]::WindowHeight

        # Calculate palette dimensions
        $paletteWidth = [Math]::Min(70, $width - 4)
        $paletteHeight = [Math]::Min(25, $height - 4)
        $paletteX = ($width - $paletteWidth) / 2
        $paletteY = ($height - $paletteHeight) / 2

        # Draw palette background
        $this.Terminal.FillArea($paletteX, $paletteY, $paletteWidth, $paletteHeight, ' ')
        $this.Terminal.DrawBox($paletteX, $paletteY, $paletteWidth, $paletteHeight)

        # Draw title
        $title = " Command Palette "
        $titleX = $paletteX + ($paletteWidth - $title.Length) / 2
        $this.Terminal.WriteAt($titleX, $paletteY, $title)

        # Draw search box
        $searchY = $paletteY + 2
        $this.Terminal.WriteAt($paletteX + 2, $searchY, "Search: ")
        $searchBoxX = $paletteX + 10
        $searchBoxWidth = $paletteWidth - 12

        # Draw search box background
        $this.Terminal.WriteAt($searchBoxX, $searchY, ('─' * $searchBoxWidth))
        $searchDisplay = $this.SearchText
        if ($searchDisplay.Length -gt $searchBoxWidth) {
            $searchDisplay = $searchDisplay.Substring($searchDisplay.Length - $searchBoxWidth + 3)
            $searchDisplay = "..." + $searchDisplay
        }
        $this.Terminal.WriteAt($searchBoxX, $searchY, $searchDisplay.PadRight($searchBoxWidth))

        # Draw cursor in search box
        $cursorX = $searchBoxX + [Math]::Min($this.SearchText.Length, $searchBoxWidth - 1)
        $this.Terminal.WriteAt($cursorX, $searchY, "`e[7m `e[0m") # Reverse video cursor

        # Draw command list header
        $listHeaderY = $searchY + 2
        $this.Terminal.WriteAt($paletteX + 2, $listHeaderY, "Command")
        $this.Terminal.WriteAt($paletteX + 25, $listHeaderY, "Category")
        $this.Terminal.WriteAt($paletteX + 35, $listHeaderY, "Description")

        # Draw separator
        $this.Terminal.WriteAt($paletteX + 1, $listHeaderY + 1, ('─' * ($paletteWidth - 2)))

        # Draw command list
        $listStartY = $listHeaderY + 2
        $visibleRows = $paletteHeight - ($listStartY - $paletteY) - 3  # Leave space for instructions

        $startIndex = [Math]::Max(0, $this.SelectedIndex - $visibleRows + 1)
        if ($startIndex + $visibleRows > $this.FilteredCommands.Count) {
            $startIndex = [Math]::Max(0, $this.FilteredCommands.Count - $visibleRows)
        }

        for ($i = 0; $i -lt $visibleRows -and ($startIndex + $i) -lt $this.FilteredCommands.Count; $i++) {
            $cmdIndex = $startIndex + $i
            $command = $this.FilteredCommands[$cmdIndex]
            $y = $listStartY + $i

            # Highlight selected command
            $isSelected = ($cmdIndex -eq $this.SelectedIndex)
            if ($isSelected) {
                $this.Terminal.WriteAt($paletteX + 1, $y, (' ' * ($paletteWidth - 2)))
                $this.Terminal.WriteAt($paletteX + 1, $y, "`e[7m") # Reverse video
            }

            # Draw command info
            $name = $command.Name
            if ($name.Length -gt 22) { $name = $name.Substring(0, 19) + "..." }

            $category = $command.Category
            if ($category.Length -gt 8) { $category = $category.Substring(0, 8) }

            $description = $command.Description
            if ($description.Length -gt ($paletteWidth - 45)) {
                $description = $description.Substring(0, $paletteWidth - 48) + "..."
            }

            $this.Terminal.WriteAt($paletteX + 2, $y, $name.PadRight(22))
            $this.Terminal.WriteAt($paletteX + 25, $y, $category.PadRight(9))
            $this.Terminal.WriteAt($paletteX + 35, $y, $description)

            # Show shortcut if available
            if ($command.Shortcut -and $command.Shortcut.Length -gt 0) {
                $shortcut = "[$($command.Shortcut)]"
                $shortcutX = $paletteX + $paletteWidth - $shortcut.Length - 2
                $this.Terminal.WriteAt($shortcutX, $y, "`e[90m$shortcut`e[0m")
            }

            if ($isSelected) {
                $this.Terminal.WriteAt($paletteX + $paletteWidth - 1, $y, "`e[0m") # Reset formatting
            }
        }

        # Draw instructions
        $instrY = $paletteY + $paletteHeight - 2
        $instructions = "↑↓: Navigate   Enter: Execute   Esc: Cancel   Type: Search"
        if ($instructions.Length -gt ($paletteWidth - 4)) {
            $instructions = "↑↓: Nav   Enter: Execute   Esc: Cancel"
        }
        $instrX = $paletteX + ($paletteWidth - $instructions.Length) / 2
        $this.Terminal.WriteAt($instrX, $instrY, "`e[90m$instructions`e[0m")

        # Show result count
        $countY = $paletteY + $paletteHeight - 3
        $countText = "Showing $($this.FilteredCommands.Count) of $($this.Commands.Count) commands"
        $countX = $paletteX + ($paletteWidth - $countText.Length) / 2
        $this.Terminal.WriteAt($countX, $countY, "`e[90m$countText`e[0m")
    }

    [void] HandleKey([System.ConsoleKeyInfo]$key) {
        switch ($key.Key) {
            'UpArrow' {
                if ($this.SelectedIndex -gt 0) {
                    $this.SelectedIndex--
                }
            }
            'DownArrow' {
                if ($this.SelectedIndex -lt ($this.FilteredCommands.Count - 1)) {
                    $this.SelectedIndex++
                }
            }
            'PageUp' {
                $this.SelectedIndex = [Math]::Max(0, $this.SelectedIndex - 10)
            }
            'PageDown' {
                $this.SelectedIndex = [Math]::Min($this.FilteredCommands.Count - 1, $this.SelectedIndex + 10)
            }
            'Home' {
                $this.SelectedIndex = 0
            }
            'End' {
                $this.SelectedIndex = [Math]::Max(0, $this.FilteredCommands.Count - 1)
            }
            'Enter' {
                if ($this.SelectedIndex -lt $this.FilteredCommands.Count) {
                    $this.SelectedCommand = $this.FilteredCommands[$this.SelectedIndex]
                    $this.IsActive = $false
                }
            }
            'Escape' {
                $this.IsActive = $false
                $this.SelectedCommand = $null
            }
            'Backspace' {
                if ($this.SearchText.Length -gt 0) {
                    $this.SearchText = $this.SearchText.Substring(0, $this.SearchText.Length - 1)
                    $this.FilterCommands()
                }
            }
            default {
                # Handle text input
                if ($key.KeyChar -and [char]::IsLetterOrDigit($key.KeyChar) -or $key.KeyChar -eq ' ') {
                    $this.SearchText += $key.KeyChar
                    $this.FilterCommands()
                }
            }
        }
    }

    [void] SaveScreen() {
        # Placeholder for screen saving
    }

    [void] RestoreScreen() {
        # Placeholder for screen restoration
    }
}

Export-ModuleMember -Function *