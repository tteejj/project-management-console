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
        $tasksMenu.Items.Add([PmcMenuItem]::new("Task List", 'L', { Write-Host "Task List not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Tomorrow", 'T', { Write-Host "Tomorrow view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Upcoming", 'U', { Write-Host "Upcoming view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Next Actions", 'N', { Write-Host "Next Actions view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("No Due Date", 'D', { Write-Host "No Due Date view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::Separator())
        $tasksMenu.Items.Add([PmcMenuItem]::new("Month View", 'M', { Write-Host "Month view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Agenda View", 'A', { Write-Host "Agenda view not implemented" }))
        $tasksMenu.Items.Add([PmcMenuItem]::new("Burndown Chart", 'B', { Write-Host "Burndown chart not implemented" }))

        # Projects menu
        $projectsMenu = $this.MenuBar.Menus[1]
        $projectsMenu.Items.Add([PmcMenuItem]::new("Project List", 'L', { $screen.LoadData() }.GetNewClosure()))
        $projectsMenu.Items.Add([PmcMenuItem]::new("Project Stats", 'S', { Write-Host "Project stats not implemented" }))
        $projectsMenu.Items.Add([PmcMenuItem]::new("Project Info", 'I', { Write-Host "Project info not implemented" }))

        # Options menu
        $optionsMenu = $this.MenuBar.Menus[2]
        $optionsMenu.Items.Add([PmcMenuItem]::new("Theme Editor", 'T', { Write-Host "Theme editor not implemented" }))
        $optionsMenu.Items.Add([PmcMenuItem]::new("Settings", 'S', { Write-Host "Settings not implemented" }))

        # Help menu
        $helpMenu = $this.MenuBar.Menus[3]
        $helpMenu.Items.Add([PmcMenuItem]::new("Help View", 'H', { Write-Host "Help view not implemented" }))
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
        }
        return $this._RenderProjectList()
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

    [bool] HandleInput([ConsoleKeyInfo]$keyInfo) {
        switch ($keyInfo.Key) {
            'UpArrow' {
                if ($this.SelectedIndex > 0) {
                    $this.SelectedIndex--
                }
                return $true
            }
            'DownArrow' {
                if ($this.SelectedIndex < $this.Projects.Count - 1) {
                    $this.SelectedIndex++
                }
                return $true
            }
            'Enter' {
                if ($this.Projects.Count > 0) {
                    $project = $this.Projects[$this.SelectedIndex]
                    $this.ShowStatus("Viewing project: $($project.name)")
                }
                return $true
            }
        }
        return $false
    }
}
