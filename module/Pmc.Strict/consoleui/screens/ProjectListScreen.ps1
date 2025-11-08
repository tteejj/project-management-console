using namespace System.Collections.Generic
using namespace System.Text

# ProjectListScreen - Project list with full CRUD operations using StandardListScreen
# Uses UniversalList widget and InlineEditor for consistent UX


Set-StrictMode -Version Latest

. "$PSScriptRoot/../base/StandardListScreen.ps1"

<#
.SYNOPSIS
Project list screen with CRUD operations

.DESCRIPTION
Shows all projects with:
- Add/Edit/Delete via InlineEditor (a/e/d keys)
- Archive/Unarchive projects
- View project statistics
- Filter and search projects
#>
class ProjectListScreen : StandardListScreen {

    # Constructor
    ProjectListScreen() : base("ProjectList", "Projects") {
        # Configure capabilities
        $this.AllowAdd = $true
        $this.AllowEdit = $true
        $this.AllowDelete = $true
        $this.AllowFilter = $true

        # Configure list columns
        $this.ConfigureColumns(@(
            @{ Name='name'; Header='Project'; Width=30; Align='left' }
            @{ Name='status'; Header='Status'; Width=12; Align='left' }
            @{ Name='task_count'; Header='Tasks'; Width=8; Align='right' }
            @{ Name='description'; Header='Description'; Width=40; Align='left' }
        ))

        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Projects"))

        # Load projects
        $this.RefreshList()
    }

    # === Abstract Method Implementations ===

    # Get entity type for store operations
    [string] GetEntityType() {
        return 'project'
    }

    # Load items from data store
    [array] LoadItems() {
        $projects = $this.Store.GetAllProjects()

        # Add computed fields
        foreach ($project in $projects) {
            # Count tasks in this project
            $project['task_count'] = ($this.Store.GetAllTasks() | Where-Object { $_.project -eq $project.name }).Count

            # Ensure status field exists
            if (-not $project.ContainsKey('status')) {
                $project['status'] = 'active'
            }
        }

        return $projects
    }

    # Define columns for list display
    [array] GetListColumns() {
        return @(
            @{ Name='name'; Header='Project'; Width=30 }
            @{ Name='status'; Header='Status'; Width=12 }
            @{ Name='task_count'; Header='Tasks'; Width=8 }
            @{ Name='description'; Header='Description'; Width=40 }
        )
    }

    # Define edit fields for InlineEditor
    [array] GetEditFields([object]$item) {
        if ($null -eq $item -or $item.Count -eq 0) {
            # New project - empty fields
            return @(
                @{ Name='name'; Type='text'; Label='Project Name'; Required=$true; Value='' }
                @{ Name='description'; Type='text'; Label='Description'; Value='' }
                @{ Name='status'; Type='text'; Label='Status'; Value='active' }
                @{ Name='goal'; Type='text'; Label='Goal'; Value='' }
            )
        } else {
            # Existing project - populate from item
            return @(
                @{ Name='name'; Type='text'; Label='Project Name'; Required=$true; Value=$item.name }
                @{ Name='description'; Type='text'; Label='Description'; Value=$item.description }
                @{ Name='status'; Type='text'; Label='Status'; Value=$item.status }
                @{ Name='goal'; Type='text'; Label='Goal'; Value=$item.goal }
            )
        }
    }

    # Handle item creation
    [void] OnItemCreated([hashtable]$values) {
        $projectData = @{
            name = $values.name
            description = $values.description
            status = $values.status
            goal = $values.goal
            created = [DateTime]::Now
        }

        $this.Store.AddProject($projectData)
        $this.SetStatusMessage("Project created: $($projectData.name)", "success")
    }

    # Handle item update
    [void] OnItemUpdated([object]$item, [hashtable]$values) {
        $changes = @{
            name = $values.name
            description = $values.description
            status = $values.status
            goal = $values.goal
        }

        $this.Store.UpdateProject($item.name, $changes)
        $this.SetStatusMessage("Project updated: $($values.name)", "success")
    }

    # Handle item deletion
    [void] OnItemDeleted([object]$item) {
        # Check if project has tasks
        $taskCount = ($this.Store.GetAllTasks() | Where-Object { $_.project -eq $item.name }).Count

        if ($taskCount -gt 0) {
            $this.SetStatusMessage("Cannot delete project with $taskCount tasks", "error")
            return
        }

        $this.Store.DeleteProject($item.name)
        $this.SetStatusMessage("Project deleted: $($item.name)", "success")
    }

    # === Custom Actions ===

    # Archive/unarchive project
    [void] ToggleProjectArchive([object]$project) {
        if ($null -eq $project) { return }

        $newStatus = if ($project.status -eq 'archived') { 'active' } else { 'archived' }
        $this.Store.UpdateProject($project.name, @{ status = $newStatus })

        $action = if ($newStatus -eq 'archived') { "archived" } else { "activated" }
        $this.SetStatusMessage("Project $action: $($project.name)", "success")
    }

    # === Input Handling ===

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        # Call parent handler first (handles list navigation, add/edit/delete)
        $handled = ([StandardListScreen]$this).HandleKeyPress($keyInfo)
        if ($handled) { return $true }

        # Custom key: R = Archive/Unarchive
        if ($keyInfo.Key -eq 'R') {
            $selected = $this.List.GetSelectedItem()
            $this.ToggleProjectArchive($selected)
            return $true
        }

        # Custom key: V = View project details/stats
        if ($keyInfo.Key -eq 'V') {
            $selected = $this.List.GetSelectedItem()
            if ($selected) {
                . "$PSScriptRoot/ProjectInfoScreen.ps1"
                $this.App.PushScreen([ProjectInfoScreen]::new($selected.name))
            }
            return $true
        }

        return $false
    }
}
