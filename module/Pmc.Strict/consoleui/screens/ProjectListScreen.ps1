using namespace System.Collections.Generic
using namespace System.Text

# ProjectListScreen - Project list with CRUD operations
# Shows all projects with ability to view, add, edit, delete, archive

. "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Main project list screen with CRUD operations

.DESCRIPTION
Shows all projects.
Supports:
- Viewing project details (Enter key)
- Adding new projects (A key)
- Editing projects (E key)
- Deleting projects (D key)
- Archiving projects (R key)
- Navigation (Up/Down arrows)
#>
class ProjectListScreen : PmcScreen {
    # Data
    [array]$Projects = @()
    [int]$SelectedIndex = 0
    [bool]$ShowArchived = $false

    # Constructor
    ProjectListScreen() : base("ProjectList", "Projects") {
        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Projects"))

        # Configure footer with shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Up/Down", "Select")
        $this.Footer.AddShortcut("Enter", "View")
        $this.Footer.AddShortcut("A", "Add")
        $this.Footer.AddShortcut("E", "Edit")
        $this.Footer.AddShortcut("R", "Archive")
        $this.Footer.AddShortcut("D", "Delete")
        $this.Footer.AddShortcut("Esc", "Back")
        $this.Footer.AddShortcut("Ctrl+Q", "Quit")

        # Setup menu items
        $this._SetupMenus()
    }

    hidden [void] _SetupMenus() {
        # Capture $this in a variable so scriptblocks can access it
        $screen = $this

        # Tasks menu - Navigate to different task views
        $tasksMenu = $this.MenuBar.Menus[0]
        $tasksMenu.Items.Add([PmcMenuItem]::new("Task List", 'L', {
            . "$PSScriptRoot/TaskListScreen.ps1"
            $global:PmcApp.PushScreen((New-Object TaskListScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Today", 'Y', {
            . "$PSScriptRoot/TodayViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object TodayViewScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Tomorrow", 'T', {
            . "$PSScriptRoot/TomorrowViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object TomorrowViewScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Week View", 'W', {
            . "$PSScriptRoot/WeekViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object WeekViewScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Upcoming", 'U', {
            . "$PSScriptRoot/UpcomingViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object UpcomingViewScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Overdue", 'V', {
            . "$PSScriptRoot/OverdueViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object OverdueViewScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Next Actions", 'N', {
            . "$PSScriptRoot/NextActionsViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object NextActionsViewScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("No Due Date", 'D', {
            . "$PSScriptRoot/NoDueDateViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object NoDueDateViewScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Blocked Tasks", 'B', {
            . "$PSScriptRoot/BlockedTasksScreen.ps1"
            $global:PmcApp.PushScreen((New-Object BlockedTasksScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::Separator())
        $tasksMenu.Items.Add([PmcMenuItem]::new("Kanban Board", 'K', {
            . "$PSScriptRoot/KanbanScreen.ps1"
            $global:PmcApp.PushScreen((New-Object KanbanScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Month View", 'M', {
            . "$PSScriptRoot/MonthViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object MonthViewScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Agenda View", 'A', {
            . "$PSScriptRoot/AgendaViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object AgendaViewScreen))
        }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Burndown Chart", 'C', {
            . "$PSScriptRoot/BurndownChartScreen.ps1"
            $global:PmcApp.PushScreen((New-Object BurndownChartScreen))
        }))

        # Projects menu
        $projectsMenu = $this.MenuBar.Menus[1]
        $projectsMenu.Items.Add([PmcMenuItem]::new("Project List", 'L', {
            . "$PSScriptRoot/ProjectListScreen.ps1"
            $global:PmcApp.PushScreen((New-Object ProjectListScreen))
        }))
        $projectsMenu.Items.Add([PmcMenuItem]::new("Project Stats", 'S', {
            . "$PSScriptRoot/ProjectStatsScreen.ps1"
            $global:PmcApp.PushScreen((New-Object ProjectStatsScreen))
        }))
        $projectsMenu.Items.Add([PmcMenuItem]::new("Project Info", 'I', {
            . "$PSScriptRoot/ProjectInfoScreen.ps1"
            $global:PmcApp.PushScreen((New-Object ProjectInfoScreen))
        }))

        # Options menu
        $optionsMenu = $this.MenuBar.Menus[2]
        $optionsMenu.Items.Add([PmcMenuItem]::new("Theme Editor", 'T', {
            . "$PSScriptRoot/ThemeEditorScreen.ps1"
            $global:PmcApp.PushScreen((New-Object ThemeEditorScreen))
        }))
        $optionsMenu.Items.Add([PmcMenuItem]::new("Settings", 'S', {
            . "$PSScriptRoot/SettingsScreen.ps1"
            $global:PmcApp.PushScreen((New-Object SettingsScreen))
        }))

        # Help menu
        $helpMenu = $this.MenuBar.Menus[3]
        $helpMenu.Items.Add([PmcMenuItem]::new("Help View", 'H', {
            . "$PSScriptRoot/HelpViewScreen.ps1"
            $global:PmcApp.PushScreen((New-Object HelpViewScreen))
        }))
        $helpMenu.Items.Add([PmcMenuItem]::new("About", 'A', { Write-Host "PMC TUI v1.0" }))
    }

    [void] LoadData() {
        $this.ShowStatus("Loading projects...")

        try {
            # Get PMC data
            $data = Get-PmcAllData

            # Filter projects based on archived status
            if ($this.ShowArchived -eq $true) {
                $this.Projects = @($data.projects | Where-Object { $_.archived -eq $true })
            } elseif ($this.ShowArchived -eq $false) {
                $this.Projects = @($data.projects | Where-Object { -not $_.archived })
            } else {
                $this.Projects = @($data.projects)
            }

            # Sort by name
            $this.Projects = @($this.Projects | Sort-Object -Property name)

            # Reset selection if out of bounds
            if ($this.SelectedIndex -ge $this.Projects.Count) {
                $this.SelectedIndex = [Math]::Max(0, $this.Projects.Count - 1)
            }

            # Update status
            if ($this.Projects.Count -eq 0) {
                $this.ShowSuccess("No projects")
            } else {
                $statusText = "$($this.Projects.Count) project"
                if ($this.Projects.Count -ne 1) { $statusText += "s" }
                if ($this.ShowArchived -eq $true) { $statusText += " (archived)" }
                elseif ($this.ShowArchived -eq $false) { $statusText += " (active)" }
                $this.ShowStatus($statusText)
            }

        } catch {
            $this.ShowError("Failed to load projects: $_")
            $this.Projects = @()
        }
    }

    [string] RenderContent() {
        if ($this.Projects.Count -eq 0) {
            return $this._RenderEmptyState()
        } else {
            return $this._RenderProjectList()
        }
    }

    hidden [string] _RenderEmptyState() {
        $sb = [System.Text.StringBuilder]::new(512)

        # Get content area
        if ($this.LayoutManager) {
            $contentRect = $this.LayoutManager.GetRegion('Content', $this.TermWidth, $this.TermHeight)

            # Center message
            $message = "No projects - Press A to add one"
            $x = $contentRect.X + [Math]::Floor(($contentRect.Width - $message.Length) / 2)
            $y = $contentRect.Y + [Math]::Floor($contentRect.Height / 2)

            $textColor = $this.Header.GetThemedAnsi('Text', $false)
            $reset = "`e[0m"

            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($textColor)
            $sb.Append($message)
            $sb.Append($reset)
        }

        return $sb.ToString()
    }

    hidden [string] _RenderProjectList() {
        $sb = [System.Text.StringBuilder]::new(4096)

        if (-not $this.LayoutManager) {
            return $sb.ToString()
        }

        # Get content area
        $contentRect = $this.LayoutManager.GetRegion('Content', $this.TermWidth, $this.TermHeight)

        # Colors
        $textColor = $this.Header.GetThemedAnsi('Text', $false)
        $selectedBg = $this.Header.GetThemedAnsi('Primary', $true)
        $selectedFg = $this.Header.GetThemedAnsi('Text', $false)
        $cursorColor = $this.Header.GetThemedAnsi('Accent', $false)
        $mutedColor = $this.Header.GetThemedAnsi('Muted', $false)
        $headerColor = $this.Header.GetThemedAnsi('Muted', $false)
        $warningColor = $this.Header.GetThemedAnsi('Warning', $false)
        $reset = "`e[0m"

        # Column widths
        $nameWidth = 30
        $statusWidth = 10
        $pathWidth = $contentRect.Width - $nameWidth - $statusWidth - 10

        # Render column headers at line 4 (ABOVE separator which is at line 5)
        $headerY = $this.Header.Y + 3
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $headerY))
        $sb.Append($headerColor)
        $sb.Append("NAME".PadRight($nameWidth))
        $sb.Append("STATUS".PadRight($statusWidth))
        $sb.Append("PATH")
        $sb.Append($reset)

        # Render project rows
        $startY = $headerY + 2
        $maxLines = $contentRect.Height - 4

        for ($i = 0; $i -lt [Math]::Min($this.Projects.Count, $maxLines); $i++) {
            $project = $this.Projects[$i]
            $y = $startY + $i
            $isSelected = ($i -eq $this.SelectedIndex)

            # Cursor
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 2, $y))
            if ($isSelected) {
                $sb.Append($cursorColor)
                $sb.Append(">")
                $sb.Append($reset)
            } else {
                $sb.Append(" ")
            }

            # Project row with columns
            $x = $contentRect.X + 4

            # Name column
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            if ($isSelected) {
                $sb.Append($selectedBg)
                $sb.Append($selectedFg)
            } else {
                $sb.Append($textColor)
            }
            $displayName = $project.name
            if ($displayName.Length > $nameWidth) {
                $displayName = $displayName.Substring(0, $nameWidth - 3) + "..."
            }
            $sb.Append($displayName.PadRight($nameWidth))
            $sb.Append($reset)
            $x += $nameWidth

            # Status column
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $statusText = if ($project.archived) { "archived" } else { "active" }
            if ($project.archived) {
                $sb.Append($warningColor)
            } else {
                $sb.Append($mutedColor)
            }
            $sb.Append($statusText.PadRight($statusWidth))
            $sb.Append($reset)
            $x += $statusWidth

            # Path column
            $sb.Append($this.Header.BuildMoveTo($x, $y))
            $sb.Append($mutedColor)
            $displayPath = if ($project.path) { $project.path } else { "(no path)" }
            if ($displayPath.Length > $pathWidth) {
                $displayPath = "..." + $displayPath.Substring($displayPath.Length - $pathWidth + 3)
            }
            $sb.Append($displayPath)
            $sb.Append($reset)
        }

        return $sb.ToString()
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        switch ($keyInfo.Key) {
            'UpArrow' {
                if ($this.SelectedIndex > 0) {
                    $this.SelectedIndex--
                }
                return $true
            }
            'DownArrow' {
                if ($this.SelectedIndex -lt ($this.Projects.Count - 1)) {
                    $this.SelectedIndex++
                }
                return $true
            }
            'Enter' {
                if ($this.Projects.Count > 0) {
                    $project = $this.Projects[$this.SelectedIndex]
                    . "$PSScriptRoot/ProjectInfoScreen.ps1"
                    $screen = New-Object ProjectInfoScreen
                    $screen.SetProject($project.name)
                    $global:PmcApp.PushScreen($screen)
                }
                return $true
            }
            'A' {
                $this._AddProject()
                return $true
            }
            'E' {
                $this._EditProject()
                return $true
            }
            'D' {
                $this._DeleteProject()
                return $true
            }
            'R' {
                $this._ArchiveProject()
                return $true
            }
        }
        return $false
    }

    hidden [void] _AddProject() {
        # Show project form dialog
        . "$PSScriptRoot/../widgets/PmcDialog.ps1"
        $dialog = New-Object ProjectFormDialog

        # Get theme for dialog rendering
        $theme = @{
            DialogBg = $this.Header.GetThemedAnsi('Background', $true)
            DialogFg = $this.Header.GetThemedAnsi('Text', $false)
            DialogBorder = $this.Header.GetThemedAnsi('Border', $false)
            Highlight = $this.Header.GetThemedAnsi('Accent', $false)
            PrimaryBg = $this.Header.GetThemedAnsi('Primary', $true)
            Muted = $this.Header.GetThemedAnsi('Muted', $false)
        }

        # Dialog loop using SpeedTUI's differential rendering
        while (-not $dialog.IsComplete) {
            # Check if file picker requested
            if ($dialog.FilePicker -eq 'show') {
                $dialog.FilePicker = ''

                # Show file picker
                . "$PSScriptRoot/../widgets/PmcFilePicker.ps1"
                $startPath = if ($dialog.Fields.path) { $dialog.Fields.path } else { [Environment]::GetFolderPath('UserProfile') }
                $picker = New-Object PmcFilePicker($startPath, $true)

                # File picker loop
                while (-not $picker.IsComplete) {
                    $this.RenderEngine.BeginFrame()

                    # Render base screen
                    $fullScreenOutput = $this.Render()
                    if ($fullScreenOutput) {
                        $global:PmcApp._WriteAnsiToEngine($fullScreenOutput)
                    }

                    # Render picker
                    $pickerOutput = $picker.Render($this.TermWidth, $this.TermHeight)
                    if ($pickerOutput) {
                        $global:PmcApp._WriteAnsiToEngine($pickerOutput)
                    }

                    $this.RenderEngine.EndFrame()

                    $key = [Console]::ReadKey($true)
                    $picker.HandleInput($key)
                }

                # If path was selected, update dialog field
                if ($picker.Result) {
                    $dialog.Fields.path = $picker.SelectedPath
                }

                # Continue with dialog
                continue
            }

            # Render through SpeedTUI engine
            $this.RenderEngine.BeginFrame()

            # Render FULL screen (menu, header, content, footer)
            $fullScreenOutput = $this.Render()
            if ($fullScreenOutput) {
                # Parse and write screen ANSI to engine
                $global:PmcApp._WriteAnsiToEngine($fullScreenOutput)
            }

            # Render dialog on top
            $dialogOutput = $dialog.Render($this.TermWidth, $this.TermHeight, $theme)
            if ($dialogOutput) {
                # Parse and write dialog ANSI to engine
                $global:PmcApp._WriteAnsiToEngine($dialogOutput)
            }

            # SpeedTUI does differential rendering here
            $this.RenderEngine.EndFrame()

            # Wait for input
            $key = [Console]::ReadKey($true)
            $dialog.HandleInput($key)
        }

        # Clear dialog by forcing full screen re-render
        [Console]::Write("`e[2J")
        if ($this.RenderEngine) {
            $this.RenderEngine.InvalidateAll()
        }

        # Process result
        if ($dialog.Result) {
            $project = $dialog.GetProject()

            # Validate
            if ([string]::IsNullOrWhiteSpace($project.name)) {
                $this.ShowError("Project name cannot be empty")
                $this.LoadData()
                return
            }

            # Check if project already exists
            $allData = Get-PmcAllData
            $existing = $allData.projects | Where-Object { $_.name -eq $project.name }
            if ($existing) {
                $this.ShowError("Project '$($project.name)' already exists")
                $this.LoadData()
                return
            }

            # Add created/archived fields
            $project.created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            $project.archived = $false

            # Save
            $allData.projects += $project
            Set-PmcAllData $allData

            $this.ShowSuccess("Project '$($project.name)' created")
            $this.LoadData()
        } else {
            $this.ShowStatus("Add cancelled")
            $this.LoadData()
        }
    }

    hidden [void] _EditProject() {
        if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.Projects.Count) {
            return
        }

        $project = $this.Projects[$this.SelectedIndex]

        # Show project form dialog with existing project data
        . "$PSScriptRoot/../widgets/PmcDialog.ps1"
        $dialog = New-Object ProjectFormDialog($project)

        # Get theme for dialog rendering
        $theme = @{
            DialogBg = $this.Header.GetThemedAnsi('Background', $true)
            DialogFg = $this.Header.GetThemedAnsi('Text', $false)
            DialogBorder = $this.Header.GetThemedAnsi('Border', $false)
            Highlight = $this.Header.GetThemedAnsi('Accent', $false)
            PrimaryBg = $this.Header.GetThemedAnsi('Primary', $true)
            Muted = $this.Header.GetThemedAnsi('Muted', $false)
        }

        # Dialog loop using SpeedTUI's differential rendering
        while (-not $dialog.IsComplete) {
            # Check if file picker requested
            if ($dialog.FilePicker -eq 'show') {
                $dialog.FilePicker = ''

                # Show file picker
                . "$PSScriptRoot/../widgets/PmcFilePicker.ps1"
                $startPath = if ($dialog.Fields.path) { $dialog.Fields.path } else { [Environment]::GetFolderPath('UserProfile') }
                $picker = New-Object PmcFilePicker($startPath, $true)

                # File picker loop
                while (-not $picker.IsComplete) {
                    $this.RenderEngine.BeginFrame()

                    # Render base screen
                    $fullScreenOutput = $this.Render()
                    if ($fullScreenOutput) {
                        $global:PmcApp._WriteAnsiToEngine($fullScreenOutput)
                    }

                    # Render picker
                    $pickerOutput = $picker.Render($this.TermWidth, $this.TermHeight)
                    if ($pickerOutput) {
                        $global:PmcApp._WriteAnsiToEngine($pickerOutput)
                    }

                    $this.RenderEngine.EndFrame()

                    $key = [Console]::ReadKey($true)
                    $picker.HandleInput($key)
                }

                # If path was selected, update dialog field
                if ($picker.Result) {
                    $dialog.Fields.path = $picker.SelectedPath
                }

                # Continue with dialog
                continue
            }

            # Render through SpeedTUI engine
            $this.RenderEngine.BeginFrame()

            # Render FULL screen (menu, header, content, footer)
            $fullScreenOutput = $this.Render()
            if ($fullScreenOutput) {
                # Parse and write screen ANSI to engine
                $global:PmcApp._WriteAnsiToEngine($fullScreenOutput)
            }

            # Render dialog on top
            $dialogOutput = $dialog.Render($this.TermWidth, $this.TermHeight, $theme)
            if ($dialogOutput) {
                # Parse and write dialog ANSI to engine
                $global:PmcApp._WriteAnsiToEngine($dialogOutput)
            }

            # SpeedTUI does differential rendering here
            $this.RenderEngine.EndFrame()

            # Wait for input
            $key = [Console]::ReadKey($true)
            $dialog.HandleInput($key)
        }

        # Clear dialog by forcing full screen re-render
        [Console]::Write("`e[2J")
        if ($this.RenderEngine) {
            $this.RenderEngine.InvalidateAll()
        }

        # Process result
        if ($dialog.Result) {
            $editedProject = $dialog.GetProject()

            # Validate
            if ([string]::IsNullOrWhiteSpace($editedProject.name)) {
                $this.ShowError("Project name cannot be empty")
                $this.LoadData()
                return
            }

            # Update storage
            $allData = Get-PmcAllData
            $projectToUpdate = $allData.projects | Where-Object { $_.name -eq $dialog.OriginalName }

            if ($projectToUpdate) {
                $projectToUpdate.name = $editedProject.name
                $projectToUpdate.description = $editedProject.description
                $projectToUpdate.path = $editedProject.path
                $projectToUpdate.aliases = $editedProject.aliases

                Set-PmcAllData $allData
                $this.ShowSuccess("Project '$($editedProject.name)' updated")
                $this.LoadData()
            } else {
                $this.ShowError("Project not found in storage")
                $this.LoadData()
            }
        } else {
            $this.ShowStatus("Edit cancelled")
            $this.LoadData()
        }
    }

    hidden [void] _DeleteProject() {
        if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.Projects.Count) {
            return
        }

        $project = $this.Projects[$this.SelectedIndex]

        # Check if project has tasks
        $allData = Get-PmcAllData
        $projectTasks = @($allData.tasks | Where-Object { $_.project -eq $project.name })
        if ($projectTasks.Count -gt 0) {
            $this.ShowError("Cannot delete project with $($projectTasks.Count) task(s). Move or delete tasks first.")
            return
        }

        # Show confirmation dialog
        . "$PSScriptRoot/../widgets/PmcDialog.ps1"
        $dialog = New-Object ConfirmDialog("Delete Project", "Delete '$($project.name)'?")

        # Get theme for dialog rendering
        $theme = @{
            DialogBg = $this.Header.GetThemedAnsi('Background', $true)
            DialogFg = $this.Header.GetThemedAnsi('Text', $false)
            DialogBorder = $this.Header.GetThemedAnsi('Border', $false)
            Highlight = $this.Header.GetThemedAnsi('Accent', $false)
            PrimaryBg = $this.Header.GetThemedAnsi('Primary', $true)
            Muted = $this.Header.GetThemedAnsi('Muted', $false)
        }

        # Dialog loop using SpeedTUI's differential rendering
        while (-not $dialog.IsComplete) {
            # Check if file picker requested
            if ($dialog.FilePicker -eq 'show') {
                $dialog.FilePicker = ''

                # Show file picker
                . "$PSScriptRoot/../widgets/PmcFilePicker.ps1"
                $startPath = if ($dialog.Fields.path) { $dialog.Fields.path } else { [Environment]::GetFolderPath('UserProfile') }
                $picker = New-Object PmcFilePicker($startPath, $true)

                # File picker loop
                while (-not $picker.IsComplete) {
                    $this.RenderEngine.BeginFrame()

                    # Render base screen
                    $fullScreenOutput = $this.Render()
                    if ($fullScreenOutput) {
                        $global:PmcApp._WriteAnsiToEngine($fullScreenOutput)
                    }

                    # Render picker
                    $pickerOutput = $picker.Render($this.TermWidth, $this.TermHeight)
                    if ($pickerOutput) {
                        $global:PmcApp._WriteAnsiToEngine($pickerOutput)
                    }

                    $this.RenderEngine.EndFrame()

                    $key = [Console]::ReadKey($true)
                    $picker.HandleInput($key)
                }

                # If path was selected, update dialog field
                if ($picker.Result) {
                    $dialog.Fields.path = $picker.SelectedPath
                }

                # Continue with dialog
                continue
            }

            # Render through SpeedTUI engine
            $this.RenderEngine.BeginFrame()

            # Render FULL screen (menu, header, content, footer)
            $fullScreenOutput = $this.Render()
            if ($fullScreenOutput) {
                # Parse and write screen ANSI to engine
                $global:PmcApp._WriteAnsiToEngine($fullScreenOutput)
            }

            # Render dialog on top
            $dialogOutput = $dialog.Render($this.TermWidth, $this.TermHeight, $theme)
            if ($dialogOutput) {
                # Parse and write dialog ANSI to engine
                $global:PmcApp._WriteAnsiToEngine($dialogOutput)
            }

            # SpeedTUI does differential rendering here
            $this.RenderEngine.EndFrame()

            # Wait for input
            $key = [Console]::ReadKey($true)
            $dialog.HandleInput($key)
        }

        # Clear dialog by forcing full screen re-render
        [Console]::Write("`e[2J")
        if ($this.RenderEngine) {
            $this.RenderEngine.InvalidateAll()
        }

        # Process result
        if ($dialog.Result) {
            # Delete project
            $allData.projects = @($allData.projects | Where-Object { $_.name -ne $project.name })
            Set-PmcAllData $allData

            $this.ShowSuccess("Project '$($project.name)' deleted")
            $this.LoadData()
        } else {
            $this.ShowStatus("Delete cancelled")
            $this.LoadData()
        }
    }

    hidden [void] _ArchiveProject() {
        if ($this.SelectedIndex -lt 0 -or $this.SelectedIndex -ge $this.Projects.Count) {
            return
        }

        $project = $this.Projects[$this.SelectedIndex]

        try {
            # Toggle archive status
            $newArchiveState = -not $project.archived

            # Update in-memory object
            $project.archived = $newArchiveState

            # Update storage
            $allData = Get-PmcAllData
            $projectToUpdate = $allData.projects | Where-Object { $_.name -eq $project.name }

            if ($projectToUpdate) {
                $projectToUpdate.archived = $newArchiveState
                Set-PmcAllData $allData

                $action = if ($newArchiveState) { "archived" } else { "unarchived" }
                $this.ShowSuccess("Project '$($project.name)' $action")

                # Reload data to reflect changes
                $this.LoadData()
            } else {
                $this.ShowError("Project not found in storage")
            }
        } catch {
            $this.ShowError("Failed to archive project: $_")
        }
    }

}
