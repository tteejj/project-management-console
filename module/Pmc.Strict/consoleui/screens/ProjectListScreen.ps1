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

    # Static: Register menu items
    static [void] RegisterMenuItems([object]$registry) {
        $registry.AddMenuItem('Projects', 'Project List', 'L', {
            . "$PSScriptRoot/ProjectListScreen.ps1"
            $global:PmcApp.PushScreen([ProjectListScreen]::new())
        }, 10)
    }

    # Constructor
    ProjectListScreen() : base("ProjectList", "Projects") {
        # Configure capabilities
        $this.AllowAdd = $true
        $this.AllowEdit = $true
        $this.AllowDelete = $true
        $this.AllowFilter = $true

        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Projects"))

        # TODO: Column configuration - StandardListScreen doesn't implement ConfigureColumns yet
        # Will use default columns from UniversalList
    }

    # === Abstract Method Implementations ===

    # Get entity type for store operations
    [string] GetEntityType() {
        return 'project'
    }

    # Load data and refresh list (required by StandardListScreen)
    [void] LoadData() {
        $items = $this.LoadItems()
        $this.List.SetData($items)
    }

    # Load items from data store
    [array] LoadItems() {
        $projects = $this.Store.GetAllProjects()

        # Add computed fields
        foreach ($project in $projects) {
            # Count tasks in this project
            $project['task_count'] = @($this.Store.GetAllTasks() | Where-Object { $_.project -eq $project.name }).Count

            # Ensure status field exists
            if (-not $project.ContainsKey('status')) {
                $project['status'] = 'active'
            }
        }

        return $projects
    }

    # Define columns for list display
    [array] GetColumns() {
        return @(
            @{ Name='name'; Label='Project'; Width=30 }
            @{ Name='status'; Label='Status'; Width=12 }
            @{ Name='task_count'; Label='Tasks'; Width=8 }
            @{ Name='description'; Label='Description'; Width=40 }
        )
    }

    # Define edit fields for InlineEditor
    [array] GetEditFields([object]$item) {
        if ($null -eq $item -or $item.Count -eq 0) {
            # New project - empty fields
            return @(
                @{ Name='name'; Type='text'; Label='Project Name'; Required=$true; Value='' }
                @{ Name='description'; Type='text'; Label='Description'; Value='' }
                @{ Name='ID1'; Type='text'; Label='ID1'; Value='' }
                @{ Name='ID2'; Type='text'; Label='ID2'; Value='' }
                @{ Name='ProjFolder'; Type='folder'; Label='Project Folder'; Value='' }
                @{ Name='AssignedDate'; Type='date'; Label='Assigned Date'; Value=$null }
                @{ Name='DueDate'; Type='date'; Label='Due Date'; Value=$null }
                @{ Name='BFDate'; Type='date'; Label='BF Date'; Value=$null }
                @{ Name='tags'; Type='text'; Label='Tags (comma-separated)'; Value='' }
            )
        } else {
            # Existing project - populate from item
            $tagsStr = if ($item.tags -and $item.tags.Count -gt 0) { $item.tags -join ', ' } else { '' }

            # Parse dates with error handling
            $assignedDate = if ($item.AssignedDate) {
                try { [DateTime]::Parse($item.AssignedDate) } catch { $null }
            } else { $null }
            $dueDate = if ($item.DueDate) {
                try { [DateTime]::Parse($item.DueDate) } catch { $null }
            } else { $null }
            $bfDate = if ($item.BFDate) {
                try { [DateTime]::Parse($item.BFDate) } catch { $null }
            } else { $null }

            return @(
                @{ Name='name'; Type='text'; Label='Project Name'; Required=$true; Value=$item.name }
                @{ Name='description'; Type='text'; Label='Description'; Value=$item.description }
                @{ Name='ID1'; Type='text'; Label='ID1'; Value=$item.ID1 }
                @{ Name='ID2'; Type='text'; Label='ID2'; Value=$item.ID2 }
                @{ Name='ProjFolder'; Type='folder'; Label='Project Folder'; Value=$item.ProjFolder }
                @{ Name='AssignedDate'; Type='date'; Label='Assigned Date'; Value=$assignedDate }
                @{ Name='DueDate'; Type='date'; Label='Due Date'; Value=$dueDate }
                @{ Name='BFDate'; Type='date'; Label='BF Date'; Value=$bfDate }
                @{ Name='tags'; Type='text'; Label='Tags (comma-separated)'; Value=$tagsStr }
            )
        }
    }

    # Handle item creation
    [void] OnItemCreated([hashtable]$values) {
        # Parse tags from comma-separated string
        $tags = @()
        if ($values.tags -and $values.tags.Trim()) {
            $tags = $values.tags -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        }

        # Format dates to ISO string
        $assignedDate = if ($values.AssignedDate -is [DateTime]) { $values.AssignedDate.ToString('yyyy-MM-dd') } else { '' }
        $dueDate = if ($values.DueDate -is [DateTime]) { $values.DueDate.ToString('yyyy-MM-dd') } else { '' }
        $bfDate = if ($values.BFDate -is [DateTime]) { $values.BFDate.ToString('yyyy-MM-dd') } else { '' }

        # H-VAL-9: Check for duplicate project name before creating
        $existingProjects = $this.Store.GetAllProjects()
        $duplicate = $existingProjects | Where-Object { $_.name -eq $values.name } | Select-Object -First 1
        if ($duplicate) {
            $this.SetStatusMessage("Project with name '$($values.name)' already exists", "error")
            return
        }

        $projectData = @{
            id = [guid]::NewGuid().ToString()
            name = $values.name
            description = $values.description
            created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            status = 'active'
            tags = $tags
            ID1 = $values.ID1
            ID2 = $values.ID2
            ProjFolder = $values.ProjFolder
            AssignedDate = $assignedDate
            DueDate = $dueDate
            BFDate = $bfDate
        }

        $success = $this.Store.AddProject($projectData)
        if ($success) {
            $this.SetStatusMessage("Project created: $($projectData.name)", "success")
        } else {
            $this.SetStatusMessage("Failed to create project: $($this.Store.LastError)", "error")
        }
    }

    # Handle item update
    [void] OnItemUpdated([object]$item, [hashtable]$values) {
        # Parse tags from comma-separated string
        $tags = @()
        if ($values.tags -and $values.tags.Trim()) {
            $tags = $values.tags -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        }

        # Format dates to ISO string
        $assignedDate = if ($values.AssignedDate -is [DateTime]) { $values.AssignedDate.ToString('yyyy-MM-dd') } else { '' }
        $dueDate = if ($values.DueDate -is [DateTime]) { $values.DueDate.ToString('yyyy-MM-dd') } else { '' }
        $bfDate = if ($values.BFDate -is [DateTime]) { $values.BFDate.ToString('yyyy-MM-dd') } else { '' }

        $changes = @{
            name = $values.name
            description = $values.description
            tags = $tags
            ID1 = $values.ID1
            ID2 = $values.ID2
            ProjFolder = $values.ProjFolder
            AssignedDate = $assignedDate
            DueDate = $dueDate
            BFDate = $bfDate
        }

        $success = $this.Store.UpdateProject($item.name, $changes)
        if ($success) {
            $this.SetStatusMessage("Project updated: $($values.name)", "success")
        } else {
            $this.SetStatusMessage("Failed to update project: $($this.Store.LastError)", "error")
        }
    }

    # Handle item deletion
    [void] OnItemDeleted([object]$item) {
        # Check if project has tasks
        $taskCount = ($this.Store.GetAllTasks() | Where-Object { $_.project -eq $item.name }).Count

        if ($taskCount -gt 0) {
            # H-UI-8: Better error message with actionable guidance
            $this.SetStatusMessage("Cannot delete project with $taskCount tasks. Reassign or delete tasks first.", "error")
            return
        }

        $success = $this.Store.DeleteProject($item.name)
        if ($success) {
            $this.SetStatusMessage("Project deleted: $($item.name)", "success")
        } else {
            $this.SetStatusMessage("Failed to delete project: $($this.Store.LastError)", "error")
        }
    }

    # === Custom Actions ===

    # Import projects from Excel spreadsheet
    [void] ImportFromExcel() {
        try {
            # Check if ImportExcel module is available
            if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
                $this.SetStatusMessage("ImportExcel module not found. Install with: Install-Module -Name ImportExcel", "error")
                return
            }

            # Import the module
            Import-Module ImportExcel -ErrorAction Stop

            # Show file picker for Excel file selection
            . "$PSScriptRoot/../widgets/PmcFilePicker.ps1"
            $filePicker = New-Object PmcFilePicker -ArgumentList $this.App
            $filePicker.Title = "Select Excel File to Import"
            $filePicker.Filter = "*.xlsx;*.xls"
            $filePicker.InitialDirectory = $global:HOME

            $excelPath = $filePicker.Show()
            if ([string]::IsNullOrWhiteSpace($excelPath)) {
                $this.SetStatusMessage("Import cancelled", "warning")
                return
            }

            # H-ERR-2: Wrap file operations in try-catch for proper error handling
            try {
                if (-not (Test-Path $excelPath)) {
                    $this.SetStatusMessage("File not found: $excelPath", "error")
                    return
                }
            }
            catch {
                $this.SetStatusMessage("Error checking file path: $($_.Exception.Message)", "error")
                return
            }

            # Load mapping configuration
            $mappingPath = "$PSScriptRoot/../config/ExcelImportMapping.json"
            if (-not (Test-Path $mappingPath)) {
                $this.SetStatusMessage("Mapping configuration not found", "error")
                return
            }

            $mappingConfig = Get-Content $mappingPath | ConvertFrom-Json
            $profile = $mappingConfig.profiles.'SVI-CAS'  # Default to SVI-CAS profile

            # Read Excel file
            $this.SetStatusMessage("Reading Excel file...", "info")
            $excelData = Import-Excel -Path $excelPath -NoHeader -DataOnly

            # Extract project data based on mapping profile
            $projectData = @{
                id = [guid]::NewGuid().ToString()
                created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                status = 'active'
            }

            $column = $profile.column
            $columnIndex = [int][char]$column - [int][char]'A'  # Convert W to 22 (0-based)

            foreach ($mapping in $profile.mappings) {
                $rowIndex = $mapping.row - 1  # Convert to 0-based

                # Get cell value
                if ($rowIndex -lt $excelData.Count) {
                    $row = $excelData[$rowIndex]
                    if ($row -is [array] -and $columnIndex -lt $row.Count) {
                        $cellValue = $row[$columnIndex]
                    } elseif ($row.PSObject.Properties.Count -gt $columnIndex) {
                        $cellValue = $row.PSObject.Properties.Value[$columnIndex]
                    } else {
                        $cellValue = $null
                    }

                    # H-SEC-2: Sanitize Excel cell values before use
                    if ($null -ne $cellValue -and -not [string]::IsNullOrWhiteSpace($cellValue)) {
                        # Convert to string and sanitize
                        $sanitized = $cellValue.ToString().Trim()

                        # Remove potentially dangerous characters for field names/descriptions
                        # Allow alphanumeric, spaces, common punctuation but block control chars
                        $sanitized = $sanitized -replace '[\x00-\x1F\x7F]', ''

                        switch ($mapping.type) {
                            'date' {
                                try {
                                    $date = [DateTime]::Parse($sanitized)
                                    $projectData[$mapping.field] = $date.ToString('yyyy-MM-dd')
                                } catch {
                                    $projectData[$mapping.field] = ''
                                }
                            }
                            'number' {
                                try {
                                    $projectData[$mapping.field] = [double]$sanitized
                                } catch {
                                    $projectData[$mapping.field] = 0
                                }
                            }
                            'array' {
                                # Split on comma or semicolon and sanitize each item
                                $items = $sanitized -split '[,;]' | ForEach-Object {
                                    $item = $_.Trim()
                                    # Remove control characters from array items
                                    $item -replace '[\x00-\x1F\x7F]', ''
                                } | Where-Object { $_ }
                                $projectData[$mapping.field] = $items
                            }
                            default {
                                $projectData[$mapping.field] = $sanitized
                            }
                        }
                    }
                }
            }

            # Validate required fields
            if ([string]::IsNullOrWhiteSpace($projectData['name'])) {
                $this.SetStatusMessage("Project name is required (row 3, column $column)", "error")
                return
            }

            # Check if project already exists
            $existing = $this.Store.GetAllProjects() | Where-Object { $_.name -eq $projectData['name'] }
            if ($existing) {
                $this.SetStatusMessage("Project '$($projectData['name'])' already exists. Use edit to update.", "warning")
                return
            }

            # Add project to store
            $success = $this.Store.AddProject($projectData)
            if ($success) {
                $this.SetStatusMessage("Project imported successfully: $($projectData['name'])", "success")
                $this.LoadData()  # Refresh list
            } else {
                $this.SetStatusMessage("Failed to import project: $($this.Store.LastError)", "error")
            }

        } catch {
            $this.SetStatusMessage("Excel import error: $($_.Exception.Message)", "error")
        }
    }

    # Archive/unarchive project
    [void] ToggleProjectArchive([object]$project) {
        if ($null -eq $project) { return }

        $newStatus = if ($project.status -eq 'archived') { 'active' } else { 'archived' }
        $this.Store.UpdateProject($project.name, @{ status = $newStatus })

        $action = if ($newStatus -eq 'archived') { "archived" } else { "activated" }
        $this.SetStatusMessage("Project ${action}: $($project.name)", "success")
    }

    # === Input Handling ===

    # Open project folder
    [void] OpenProjectFolder([object]$project) {
        if ($null -eq $project) { return }

        $folderPath = $project.ProjFolder
        if ([string]::IsNullOrWhiteSpace($folderPath)) {
            $this.SetStatusMessage("Project has no folder path set", "warning")
            return
        }

        # H-SEC-1: Sanitize and validate file path before use
        try {
            # Resolve to absolute path and validate it's a directory
            $resolvedPath = Resolve-Path -Path $folderPath -ErrorAction Stop
            if (-not (Test-Path -Path $resolvedPath -PathType Container)) {
                $this.SetStatusMessage("Path is not a directory: $folderPath", "error")
                return
            }
            $folderPath = $resolvedPath.Path
        }
        catch {
            $this.SetStatusMessage("Invalid or inaccessible folder path: $folderPath", "error")
            return
        }

        try {
            # Use proper Start-Process parameters with validated path
            if ($global:IsLinux) {
                Start-Process -FilePath "xdg-open" -ArgumentList @($folderPath)
            } elseif ($global:IsMacOS) {
                Start-Process -FilePath "open" -ArgumentList @($folderPath)
            } else {
                Start-Process -FilePath "explorer.exe" -ArgumentList @($folderPath)
            }
            $this.SetStatusMessage("Opened folder: $folderPath", "success")
        } catch {
            $this.SetStatusMessage("Failed to open folder: $($_.Exception.Message)", "error")
        }
    }

    # Get custom actions for footer display
    [array] GetCustomActions() {
        $self = $this
        return @(
            @{ Key='r'; Label='Archive'; Callback={
                $selected = $self.List.GetSelectedItem()
                $self.ToggleProjectArchive($selected)
            }.GetNewClosure() }
            @{ Key='v'; Label='View'; Callback={
                $selected = $self.List.GetSelectedItem()
                if ($selected) {
                    . "$PSScriptRoot/ProjectInfoScreen.ps1"
                    $screen = New-Object ProjectInfoScreen -ArgumentList $selected.name
                    $self.App.PushScreen($screen)
                }
            }.GetNewClosure() }
            @{ Key='o'; Label='Open Folder'; Callback={
                $selected = $self.List.GetSelectedItem()
                $self.OpenProjectFolder($selected)
            }.GetNewClosure() }
            @{ Key='i'; Label='Import Excel'; Callback={
                $self.ImportFromExcel()
            }.GetNewClosure() }
        )
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        # Call parent handler first (handles list navigation, add/edit/delete)
        $handled = ([StandardListScreen]$this).HandleKeyPress($keyInfo)
        if ($handled) { return $true }

        # Custom key: R = Archive/Unarchive
        if ($keyInfo.KeyChar -eq 'r' -or $keyInfo.KeyChar -eq 'R') {
            $selected = $this.List.GetSelectedItem()
            $this.ToggleProjectArchive($selected)
            return $true
        }

        # Custom key: V = View project details/stats
        if ($keyInfo.KeyChar -eq 'v' -or $keyInfo.KeyChar -eq 'V') {
            $selected = $this.List.GetSelectedItem()
            if ($selected) {
                . "$PSScriptRoot/ProjectInfoScreen.ps1"
                $screen = New-Object ProjectInfoScreen -ArgumentList $selected.name
                $this.App.PushScreen($screen)
            }
            return $true
        }

        # Custom key: O = Open project folder
        if ($keyInfo.KeyChar -eq 'o' -or $keyInfo.KeyChar -eq 'O') {
            $selected = $this.List.GetSelectedItem()
            $this.OpenProjectFolder($selected)
            return $true
        }

        # Custom key: I = Import from Excel
        if ($keyInfo.KeyChar -eq 'i' -or $keyInfo.KeyChar -eq 'I') {
            $this.ImportFromExcel()
            return $true
        }

        return $false
    }
}
