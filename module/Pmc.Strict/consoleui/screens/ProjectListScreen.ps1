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

NOTE: Uses lazy-loaded PmcFilePicker widget for folder browsing
#>
class ProjectListScreen : StandardListScreen {
    # File picker for folder browsing (lazy-loaded)
    [object]$FilePicker = $null
    [bool]$ShowFilePicker = $false

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

    # Constructor with container (DI-enabled)
    ProjectListScreen([object]$container) : base("ProjectList", "Projects", $container) {
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
            $project['task_count'] = @($this.Store.GetAllTasks() | Where-Object { (Get-SafeProperty $_ 'project') -eq (Get-SafeProperty $project 'name') }).Count

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
            $tags = Get-SafeProperty $item 'tags'
            $tagsStr = if ($tags -and $tags.Count -gt 0) { $tags -join ', ' } else { '' }

            # Parse dates with error handling
            $assignedDateValue = Get-SafeProperty $item 'AssignedDate'
            $assignedDate = if ($assignedDateValue) {
                try { [DateTime]::Parse($assignedDateValue) } catch { $null }
            } else { $null }
            $dueDateValue = Get-SafeProperty $item 'DueDate'
            $dueDate = if ($dueDateValue) {
                try { [DateTime]::Parse($dueDateValue) } catch { $null }
            } else { $null }
            $bfDateValue = Get-SafeProperty $item 'BFDate'
            $bfDate = if ($bfDateValue) {
                try { [DateTime]::Parse($bfDateValue) } catch { $null }
            } else { $null }

            return @(
                @{ Name='name'; Type='text'; Label='Project Name'; Required=$true; Value=(Get-SafeProperty $item 'name') }
                @{ Name='description'; Type='text'; Label='Description'; Value=(Get-SafeProperty $item 'description') }
                @{ Name='ID1'; Type='text'; Label='ID1'; Value=(Get-SafeProperty $item 'ID1') }
                @{ Name='ID2'; Type='text'; Label='ID2'; Value=(Get-SafeProperty $item 'ID2') }
                @{ Name='ProjFolder'; Type='folder'; Label='Project Folder'; Value=(Get-SafeProperty $item 'ProjFolder') }
                @{ Name='AssignedDate'; Type='date'; Label='Assigned Date'; Value=$assignedDate }
                @{ Name='DueDate'; Type='date'; Label='Due Date'; Value=$dueDate }
                @{ Name='BFDate'; Type='date'; Label='BF Date'; Value=$bfDate }
                @{ Name='tags'; Type='text'; Label='Tags (comma-separated)'; Value=$tagsStr }
            )
        }
    }

    # Handle item creation
    [void] OnItemCreated([hashtable]$values) {
        try {
            # Validate required field
            if (-not $values.ContainsKey('name') -or [string]::IsNullOrWhiteSpace($values.name)) {
                $this.SetStatusMessage("Project name is required", "error")
                return
            }

            # Validate name length
            if ($values.name.Length -gt 100) {
                $this.SetStatusMessage("Project name must be 100 characters or less", "error")
                return
            }

            # Validate description length if provided
            if ($values.ContainsKey('description') -and $values.description -and $values.description.Length -gt 500) {
                $this.SetStatusMessage("Description must be 500 characters or less", "error")
                return
            }

            # Parse tags from comma-separated string
            $tags = @()
            if ($values.ContainsKey('tags') -and $values.tags -and $values.tags.Trim()) {
                $tags = $values.tags -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
                # Validate tag count
                if ($tags.Count -gt 10) {
                    $this.SetStatusMessage("Maximum 10 tags allowed", "error")
                    return
                }
            }

            # Format dates to ISO string with validation
            $assignedDate = ''
            if ($values.ContainsKey('AssignedDate') -and $values.AssignedDate -is [DateTime]) {
                # Validate date range
                $minDate = [DateTime]::new(2000, 1, 1)
                $maxDate = [DateTime]::Today.AddYears(10)
                if ($values.AssignedDate -lt $minDate -or $values.AssignedDate -gt $maxDate) {
                    $this.SetStatusMessage("Assigned date must be between 2000 and 10 years from now", "warning")
                    # Continue without the date
                } else {
                    $assignedDate = $values.AssignedDate.ToString('yyyy-MM-dd')
                }
            }

            $dueDate = ''
            if ($values.ContainsKey('DueDate') -and $values.DueDate -is [DateTime]) {
                # Validate date range
                $minDate = [DateTime]::Today.AddDays(-30) # Allow past month for existing projects
                $maxDate = [DateTime]::Today.AddYears(10)
                if ($values.DueDate -lt $minDate -or $values.DueDate -gt $maxDate) {
                    $this.SetStatusMessage("Due date must be within reasonable range", "warning")
                    # Continue without the date
                } else {
                    $dueDate = $values.DueDate.ToString('yyyy-MM-dd')
                }
            }

            $bfDate = ''
            if ($values.ContainsKey('BFDate') -and $values.BFDate -is [DateTime]) {
                $bfDate = $values.BFDate.ToString('yyyy-MM-dd')
            }

            # Check for duplicate project name before creating
            $existingProjects = $this.Store.GetAllProjects()

            $projectData = @{
                id = [guid]::NewGuid().ToString()
                name = $values.name
                description = if ($values.ContainsKey('description')) { $values.description } else { '' }
                created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                status = 'active'
                tags = $tags
                ID1 = if ($values.ContainsKey('ID1')) { $values.ID1 } else { '' }
                ID2 = if ($values.ContainsKey('ID2')) { $values.ID2 } else { '' }
                ProjFolder = if ($values.ContainsKey('ProjFolder')) { $values.ProjFolder } else { '' }
                AssignedDate = $assignedDate
                DueDate = $dueDate
                BFDate = $bfDate
            }

            # Use ValidationHelper for comprehensive validation
            . "$PSScriptRoot/../helpers/ValidationHelper.ps1"
            $validationResult = Test-ProjectValid $projectData -existingProjects $existingProjects

            if (-not $validationResult.IsValid) {
                # Show first validation error
                $errorMsg = if ($validationResult.Errors.Count -gt 0) {
                    $validationResult.Errors[0]
                } else {
                    "Validation failed"
                }
                $this.SetStatusMessage($errorMsg, "error")
                Write-PmcTuiLog "Project validation failed: $($validationResult.Errors -join ', ')" "ERROR"
                return
            }

            $success = $this.Store.AddProject($projectData)
            if ($success) {
                $this.SetStatusMessage("Project created: $($projectData.name)", "success")
            } else {
                $this.SetStatusMessage("Failed to create project: $($this.Store.LastError)", "error")
            }
        } catch {
            Write-PmcTuiLog "OnItemCreated exception: $_" "ERROR"
            $this.SetStatusMessage("Unexpected error: $($_.Exception.Message)", "error")
        }
    }

    # Handle item update
    [void] OnItemUpdated([object]$item, [hashtable]$values) {
        try {
            # ENDEMIC FIX: Validate required field
            if (-not $values.ContainsKey('name') -or [string]::IsNullOrWhiteSpace($values.name)) {
                $this.SetStatusMessage("Project name is required", "error")
                return
            }

            # Parse tags from comma-separated string
            $tags = @()
            if ($values.ContainsKey('tags') -and $values.tags -and $values.tags.Trim()) {
                $tags = $values.tags -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
            }

            # Format dates to ISO string with safe access
            $assignedDate = ''
            if ($values.ContainsKey('AssignedDate') -and $values.AssignedDate -is [DateTime]) {
                $assignedDate = $values.AssignedDate.ToString('yyyy-MM-dd')
            }

            $dueDate = ''
            if ($values.ContainsKey('DueDate') -and $values.DueDate -is [DateTime]) {
                $dueDate = $values.DueDate.ToString('yyyy-MM-dd')
            }

            $bfDate = ''
            if ($values.ContainsKey('BFDate') -and $values.BFDate -is [DateTime]) {
                $bfDate = $values.BFDate.ToString('yyyy-MM-dd')
            }

            $changes = @{
                name = $values.name
                description = if ($values.ContainsKey('description')) { $values.description } else { '' }
                tags = $tags
                ID1 = if ($values.ContainsKey('ID1')) { $values.ID1 } else { '' }
                ID2 = if ($values.ContainsKey('ID2')) { $values.ID2 } else { '' }
                ProjFolder = if ($values.ContainsKey('ProjFolder')) { $values.ProjFolder } else { '' }
                AssignedDate = $assignedDate
                DueDate = $dueDate
                BFDate = $bfDate
            }

            $success = $this.Store.UpdateProject((Get-SafeProperty $item 'name'), $changes)
            if ($success) {
                $this.SetStatusMessage("Project updated: $($values.name)", "success")
            } else {
                $this.SetStatusMessage("Failed to update project: $($this.Store.LastError)", "error")
            }
        } catch {
            Write-PmcTuiLog "OnItemUpdated exception: $_" "ERROR"
            $this.SetStatusMessage("Unexpected error: $($_.Exception.Message)", "error")
        }
    }

    # Handle item deletion
    [void] OnItemDeleted([object]$item) {
        # Check if project has tasks
        $itemName = Get-SafeProperty $item 'name'
        $taskCount = ($this.Store.GetAllTasks() | Where-Object { (Get-SafeProperty $_ 'project') -eq $itemName }).Count

        if ($taskCount -gt 0) {
            # H-UI-8: Better error message with actionable guidance
            $this.SetStatusMessage("Cannot delete project with $taskCount tasks. Reassign or delete tasks first.", "error")
            return
        }

        $success = $this.Store.DeleteProject($itemName)
        if ($success) {
            $this.SetStatusMessage("Project deleted: $itemName", "success")
        } else {
            $this.SetStatusMessage("Failed to delete project: $($this.Store.LastError)", "error")
        }
    }

    # === Custom Actions ===

    # Ensure PmcFilePicker is loaded (lazy loading pattern)
    hidden [void] EnsureFilePicker() {
        if ($null -eq ([Type]'PmcFilePicker' -as [Type])) {
            Write-PmcTuiLog "ProjectListScreen: Lazy-loading PmcFilePicker widget" "DEBUG"
            . "$PSScriptRoot/../widgets/PmcFilePicker.ps1"
        }
    }

    # Import projects from Excel spreadsheet
    [void] ImportFromExcel() {
        $this.EnsureFilePicker()
        try {
            # Check if ImportExcel module is available
            if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
                $this.SetStatusMessage("ImportExcel module not found. Install with: Install-Module -Name ImportExcel", "error")
                return
            }

            # Import the module
            Import-Module ImportExcel -ErrorAction Stop

            # Show file picker for Excel file selection - use integrated file picker
            $startPath = if (Test-Path $global:HOME) { $global:HOME } else { (Get-Location).Path }
            $this.FilePicker = [PmcFilePicker]::new($startPath, $false)  # false = allow files
            $this.ShowFilePicker = $true
            $this.SetStatusMessage("Select Excel file (*.xlsx, *.xls)", "info")

            # Wait for file picker to complete
            # Note: This blocks - in real implementation this should be async
            # For now, just show message that this needs implementation
            $this.SetStatusMessage("Excel import file picker needs async implementation - use file path directly for now", "warning")
            return

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
            $existing = $this.Store.GetAllProjects() | Where-Object { (Get-SafeProperty $_ 'name') -eq $projectData['name'] }
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

        $projectStatus = Get-SafeProperty $project 'status'
        $projectName = Get-SafeProperty $project 'name'
        $newStatus = if ($projectStatus -eq 'archived') { 'active' } else { 'archived' }
        $this.Store.UpdateProject($projectName, @{ status = $newStatus })

        $action = if ($newStatus -eq 'archived') { "archived" } else { "activated" }
        $this.SetStatusMessage("Project ${action}: $projectName", "success")
    }

    # === Input Handling ===

    # Open project folder
    [void] OpenProjectFolder([object]$project) {
        $this.EnsureFilePicker()

        if ($null -eq $project) { return }

        $folderPath = Get-SafeProperty $project 'ProjFolder'
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
            # Show integrated file picker to browse the project folder
            $this.FilePicker = [PmcFilePicker]::new($folderPath, $true)
            $this.ShowFilePicker = $true
            $this.SetStatusMessage("Browsing folder: $folderPath", "info")
        } catch {
            $this.SetStatusMessage("Failed to open file picker: $($_.Exception.Message)", "error")
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
                    $screen = New-Object ProjectInfoScreen
                    $screen.SetProject((Get-SafeProperty $selected 'name'))
                    $global:PmcApp.PushScreen($screen)
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

    # Override Render to show file picker overlay
    [string] RenderContent() {
        $output = ([StandardListScreen]$this).RenderContent()

        # Render file picker overlay if showing
        if ($this.ShowFilePicker -and $null -ne $this.FilePicker) {
            $output += $this.FilePicker.Render($this.TermWidth, $this.TermHeight)
        }

        return $output
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        # CRITICAL: Call parent FIRST for MenuBar, F10, Alt+keys, content widgets
        $handled = ([PmcScreen]$this).HandleKeyPress($keyInfo)
        if ($handled) { return $true }

        # If file picker is showing, route input to it
        if ($this.ShowFilePicker -and $null -ne $this.FilePicker) {
            $handled = $this.FilePicker.HandleInput($keyInfo)

            # Check if file picker completed
            if ($this.FilePicker.IsComplete) {
                if ($this.FilePicker.Result) {
                    # User selected a folder
                    $selectedPath = $this.FilePicker.SelectedPath
                    $this.SetStatusMessage("Selected: $selectedPath", "success")
                    # Could potentially open the selected folder in system file manager
                    # Or just show the selected path
                } else {
                    $this.SetStatusMessage("Folder browsing cancelled", "info")
                }
                # Close file picker
                $this.ShowFilePicker = $false
                $this.FilePicker = $null
            }

            return $true
        }

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
                $screen = New-Object ProjectInfoScreen
                $screen.SetProject((Get-SafeProperty $selected 'name'))
                $global:PmcApp.PushScreen($screen)
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
