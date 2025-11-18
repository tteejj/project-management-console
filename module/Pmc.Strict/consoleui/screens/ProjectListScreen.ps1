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

        # PERFORMANCE FIX: Load all tasks once and build hashtable index - O(n) instead of O(n*m)
        $allTasks = $this.Store.GetAllTasks()
        $tasksByProject = @{}
        foreach ($task in $allTasks) {
            $projName = Get-SafeProperty $task 'project'
            if ($projName) {
                if (-not $tasksByProject.ContainsKey($projName)) {
                    $tasksByProject[$projName] = 0
                }
                $tasksByProject[$projName]++
            }
        }

        # Add computed fields with O(1) lookup
        foreach ($project in $projects) {
            # Count tasks in this project using hashtable lookup
            $projName = Get-SafeProperty $project 'name'
            $project['task_count'] = if ($tasksByProject.ContainsKey($projName)) {
                $tasksByProject[$projName]
            } else { 0 }

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
            @{ Name='name'; Label='Project'; Width=30; Align='left' }
            @{ Name='status'; Label='Status'; Width=12; Align='left' }
            @{ Name='task_count'; Label='Tasks'; Width=8; Align='center' }
            @{ Name='description'; Label='Description'; Width=40; Align='left' }
        )
    }

    # Define edit fields for InlineEditor
    [array] GetEditFields([object]$item) {
        if ($null -eq $item -or $item.Count -eq 0) {
            # New project - empty fields (48 Excel fields)
            return @(
                # Core fields
                @{ Name='name'; Type='text'; Label='Project Name'; Required=$true; Value='' }
                @{ Name='description'; Type='text'; Label='Description'; Value='' }
                @{ Name='status'; Type='text'; Label='Status'; Value='active' }
                @{ Name='tags'; Type='text'; Label='Tags (comma-separated)'; Value='' }

                # ID fields
                @{ Name='ID1'; Type='text'; Label='ID1'; Value='' }
                @{ Name='ID2'; Type='text'; Label='ID2'; Value='' }

                # Path fields
                @{ Name='ProjFolder'; Type='folder'; Label='Project Folder'; Value='' }
                @{ Name='CAAName'; Type='file'; Label='CAA Name'; Value='' }
                @{ Name='RequestName'; Type='file'; Label='Request Name'; Value='' }
                @{ Name='T2020'; Type='file'; Label='T2020'; Value='' }

                # Date fields
                @{ Name='AssignedDate'; Type='date'; Label='Assigned Date'; Value=$null }
                @{ Name='DueDate'; Type='date'; Label='Due Date'; Value=$null }
                @{ Name='BFDate'; Type='date'; Label='BF Date'; Value=$null }

                # Project Info (9 fields)
                @{ Name='RequestDate'; Type='date'; Label='Request Date'; Value=$null }
                @{ Name='AuditType'; Type='text'; Label='Audit Type'; Value='' }
                @{ Name='AuditorName'; Type='text'; Label='Auditor Name'; Value='' }
                @{ Name='AuditorPhone'; Type='text'; Label='Auditor Phone'; Value='' }
                @{ Name='AuditorTL'; Type='text'; Label='Auditor TL'; Value='' }
                @{ Name='AuditorTLPhone'; Type='text'; Label='Auditor TL Phone'; Value='' }
                @{ Name='AuditCase'; Type='text'; Label='Audit Case'; Value='' }
                @{ Name='CASCase'; Type='text'; Label='CAS Case'; Value='' }
                @{ Name='AuditStartDate'; Type='date'; Label='Audit Start Date'; Value=$null }

                # Contact Details (10 fields)
                @{ Name='TPName'; Type='text'; Label='TP Name'; Value='' }
                @{ Name='TPNum'; Type='text'; Label='TP Number'; Value='' }
                @{ Name='Address'; Type='text'; Label='Address'; Value='' }
                @{ Name='City'; Type='text'; Label='City'; Value='' }
                @{ Name='Province'; Type='text'; Label='Province'; Value='' }
                @{ Name='PostalCode'; Type='text'; Label='Postal Code'; Value='' }
                @{ Name='Country'; Type='text'; Label='Country'; Value='' }

                # Audit Periods (10 fields)
                @{ Name='AuditPeriodFrom'; Type='date'; Label='Audit Period From'; Value=$null }
                @{ Name='AuditPeriodTo'; Type='date'; Label='Audit Period To'; Value=$null }
                @{ Name='AuditPeriod1Start'; Type='date'; Label='Audit Period 1 Start'; Value=$null }
                @{ Name='AuditPeriod1End'; Type='date'; Label='Audit Period 1 End'; Value=$null }
                @{ Name='AuditPeriod2Start'; Type='date'; Label='Audit Period 2 Start'; Value=$null }
                @{ Name='AuditPeriod2End'; Type='date'; Label='Audit Period 2 End'; Value=$null }
                @{ Name='AuditPeriod3Start'; Type='date'; Label='Audit Period 3 Start'; Value=$null }
                @{ Name='AuditPeriod3End'; Type='date'; Label='Audit Period 3 End'; Value=$null }
                @{ Name='AuditPeriod4Start'; Type='date'; Label='Audit Period 4 Start'; Value=$null }
                @{ Name='AuditPeriod4End'; Type='date'; Label='Audit Period 4 End'; Value=$null }
                @{ Name='AuditPeriod5Start'; Type='date'; Label='Audit Period 5 Start'; Value=$null }
                @{ Name='AuditPeriod5End'; Type='date'; Label='Audit Period 5 End'; Value=$null }

                # Contacts (10 fields)
                @{ Name='Contact1Name'; Type='text'; Label='Contact 1 Name'; Value='' }
                @{ Name='Contact1Phone'; Type='text'; Label='Contact 1 Phone'; Value='' }
                @{ Name='Contact1Ext'; Type='text'; Label='Contact 1 Ext'; Value='' }
                @{ Name='Contact1Address'; Type='text'; Label='Contact 1 Address'; Value='' }
                @{ Name='Contact1Title'; Type='text'; Label='Contact 1 Title'; Value='' }
                @{ Name='Contact2Name'; Type='text'; Label='Contact 2 Name'; Value='' }
                @{ Name='Contact2Phone'; Type='text'; Label='Contact 2 Phone'; Value='' }
                @{ Name='Contact2Ext'; Type='text'; Label='Contact 2 Ext'; Value='' }
                @{ Name='Contact2Address'; Type='text'; Label='Contact 2 Address'; Value='' }
                @{ Name='Contact2Title'; Type='text'; Label='Contact 2 Title'; Value='' }

                # System Info (7 fields)
                @{ Name='AuditProgram'; Type='text'; Label='Audit Program'; Value='' }
                @{ Name='AccountingSoftware1'; Type='text'; Label='Accounting Software 1'; Value='' }
                @{ Name='AccountingSoftware1Other'; Type='text'; Label='Accounting Software 1 Other'; Value='' }
                @{ Name='AccountingSoftware1Type'; Type='text'; Label='Accounting Software 1 Type'; Value='' }
                @{ Name='AccountingSoftware2'; Type='text'; Label='Accounting Software 2'; Value='' }
                @{ Name='AccountingSoftware2Other'; Type='text'; Label='Accounting Software 2 Other'; Value='' }
                @{ Name='AccountingSoftware2Type'; Type='text'; Label='Accounting Software 2 Type'; Value='' }
                @{ Name='Comments'; Type='text'; Label='Comments'; Value='' }

                # Additional (2 fields)
                @{ Name='FXInfo'; Type='text'; Label='FX Info'; Value='' }
                @{ Name='ShipToAddress'; Type='text'; Label='Ship To Address'; Value='' }
            )
        } else {
            # Existing project - populate from item
            # Helper to convert array to comma-separated string
            $arrayToStr = {
                param($arr)
                if ($arr -and $arr.Count -gt 0) { $arr -join ', ' } else { '' }
            }

            # Helper to parse dates
            $parseDate = {
                param($val)
                if ($val) {
                    try { [DateTime]::Parse($val) } catch { $null }
                } else { $null }
            }

            return @(
                # Core fields
                @{ Name='name'; Type='text'; Label='Project Name'; Required=$true; Value=(Get-SafeProperty $item 'name') }
                @{ Name='description'; Type='text'; Label='Description'; Value=(Get-SafeProperty $item 'description') }
                @{ Name='status'; Type='text'; Label='Status'; Value=(Get-SafeProperty $item 'status') }
                @{ Name='tags'; Type='text'; Label='Tags (comma-separated)'; Value=(& $arrayToStr (Get-SafeProperty $item 'tags')) }

                # ID fields
                @{ Name='ID1'; Type='text'; Label='ID1'; Value=(Get-SafeProperty $item 'ID1') }
                @{ Name='ID2'; Type='text'; Label='ID2'; Value=(Get-SafeProperty $item 'ID2') }

                # Path fields
                @{ Name='ProjFolder'; Type='folder'; Label='Project Folder'; Value=(Get-SafeProperty $item 'ProjFolder') }
                @{ Name='CAAName'; Type='file'; Label='CAA Name'; Value=(Get-SafeProperty $item 'CAAName') }
                @{ Name='RequestName'; Type='file'; Label='Request Name'; Value=(Get-SafeProperty $item 'RequestName') }
                @{ Name='T2020'; Type='file'; Label='T2020'; Value=(Get-SafeProperty $item 'T2020') }

                # Date fields
                @{ Name='AssignedDate'; Type='date'; Label='Assigned Date'; Value=(& $parseDate (Get-SafeProperty $item 'AssignedDate')) }
                @{ Name='DueDate'; Type='date'; Label='Due Date'; Value=(& $parseDate (Get-SafeProperty $item 'DueDate')) }
                @{ Name='BFDate'; Type='date'; Label='BF Date'; Value=(& $parseDate (Get-SafeProperty $item 'BFDate')) }

                # Project Info (9 fields)
                @{ Name='RequestDate'; Type='date'; Label='Request Date'; Value=(& $parseDate (Get-SafeProperty $item 'RequestDate')) }
                @{ Name='AuditType'; Type='text'; Label='Audit Type'; Value=(Get-SafeProperty $item 'AuditType') }
                @{ Name='AuditorName'; Type='text'; Label='Auditor Name'; Value=(Get-SafeProperty $item 'AuditorName') }
                @{ Name='AuditorPhone'; Type='text'; Label='Auditor Phone'; Value=(Get-SafeProperty $item 'AuditorPhone') }
                @{ Name='AuditorTL'; Type='text'; Label='Auditor TL'; Value=(Get-SafeProperty $item 'AuditorTL') }
                @{ Name='AuditorTLPhone'; Type='text'; Label='Auditor TL Phone'; Value=(Get-SafeProperty $item 'AuditorTLPhone') }
                @{ Name='AuditCase'; Type='text'; Label='Audit Case'; Value=(Get-SafeProperty $item 'AuditCase') }
                @{ Name='CASCase'; Type='text'; Label='CAS Case'; Value=(Get-SafeProperty $item 'CASCase') }
                @{ Name='AuditStartDate'; Type='date'; Label='Audit Start Date'; Value=(& $parseDate (Get-SafeProperty $item 'AuditStartDate')) }

                # Contact Details (10 fields)
                @{ Name='TPName'; Type='text'; Label='TP Name'; Value=(Get-SafeProperty $item 'TPName') }
                @{ Name='TPNum'; Type='text'; Label='TP Number'; Value=(Get-SafeProperty $item 'TPNum') }
                @{ Name='Address'; Type='text'; Label='Address'; Value=(Get-SafeProperty $item 'Address') }
                @{ Name='City'; Type='text'; Label='City'; Value=(Get-SafeProperty $item 'City') }
                @{ Name='Province'; Type='text'; Label='Province'; Value=(Get-SafeProperty $item 'Province') }
                @{ Name='PostalCode'; Type='text'; Label='Postal Code'; Value=(Get-SafeProperty $item 'PostalCode') }
                @{ Name='Country'; Type='text'; Label='Country'; Value=(Get-SafeProperty $item 'Country') }

                # Audit Periods (10 fields)
                @{ Name='AuditPeriodFrom'; Type='date'; Label='Audit Period From'; Value=(& $parseDate (Get-SafeProperty $item 'AuditPeriodFrom')) }
                @{ Name='AuditPeriodTo'; Type='date'; Label='Audit Period To'; Value=(& $parseDate (Get-SafeProperty $item 'AuditPeriodTo')) }
                @{ Name='AuditPeriod1Start'; Type='date'; Label='Audit Period 1 Start'; Value=(& $parseDate (Get-SafeProperty $item 'AuditPeriod1Start')) }
                @{ Name='AuditPeriod1End'; Type='date'; Label='Audit Period 1 End'; Value=(& $parseDate (Get-SafeProperty $item 'AuditPeriod1End')) }
                @{ Name='AuditPeriod2Start'; Type='date'; Label='Audit Period 2 Start'; Value=(& $parseDate (Get-SafeProperty $item 'AuditPeriod2Start')) }
                @{ Name='AuditPeriod2End'; Type='date'; Label='Audit Period 2 End'; Value=(& $parseDate (Get-SafeProperty $item 'AuditPeriod2End')) }
                @{ Name='AuditPeriod3Start'; Type='date'; Label='Audit Period 3 Start'; Value=(& $parseDate (Get-SafeProperty $item 'AuditPeriod3Start')) }
                @{ Name='AuditPeriod3End'; Type='date'; Label='Audit Period 3 End'; Value=(& $parseDate (Get-SafeProperty $item 'AuditPeriod3End')) }
                @{ Name='AuditPeriod4Start'; Type='date'; Label='Audit Period 4 Start'; Value=(& $parseDate (Get-SafeProperty $item 'AuditPeriod4Start')) }
                @{ Name='AuditPeriod4End'; Type='date'; Label='Audit Period 4 End'; Value=(& $parseDate (Get-SafeProperty $item 'AuditPeriod4End')) }
                @{ Name='AuditPeriod5Start'; Type='date'; Label='Audit Period 5 Start'; Value=(& $parseDate (Get-SafeProperty $item 'AuditPeriod5Start')) }
                @{ Name='AuditPeriod5End'; Type='date'; Label='Audit Period 5 End'; Value=(& $parseDate (Get-SafeProperty $item 'AuditPeriod5End')) }

                # Contacts (10 fields)
                @{ Name='Contact1Name'; Type='text'; Label='Contact 1 Name'; Value=(Get-SafeProperty $item 'Contact1Name') }
                @{ Name='Contact1Phone'; Type='text'; Label='Contact 1 Phone'; Value=(Get-SafeProperty $item 'Contact1Phone') }
                @{ Name='Contact1Ext'; Type='text'; Label='Contact 1 Ext'; Value=(Get-SafeProperty $item 'Contact1Ext') }
                @{ Name='Contact1Address'; Type='text'; Label='Contact 1 Address'; Value=(Get-SafeProperty $item 'Contact1Address') }
                @{ Name='Contact1Title'; Type='text'; Label='Contact 1 Title'; Value=(Get-SafeProperty $item 'Contact1Title') }
                @{ Name='Contact2Name'; Type='text'; Label='Contact 2 Name'; Value=(Get-SafeProperty $item 'Contact2Name') }
                @{ Name='Contact2Phone'; Type='text'; Label='Contact 2 Phone'; Value=(Get-SafeProperty $item 'Contact2Phone') }
                @{ Name='Contact2Ext'; Type='text'; Label='Contact 2 Ext'; Value=(Get-SafeProperty $item 'Contact2Ext') }
                @{ Name='Contact2Address'; Type='text'; Label='Contact 2 Address'; Value=(Get-SafeProperty $item 'Contact2Address') }
                @{ Name='Contact2Title'; Type='text'; Label='Contact 2 Title'; Value=(Get-SafeProperty $item 'Contact2Title') }

                # System Info (7 fields)
                @{ Name='AuditProgram'; Type='text'; Label='Audit Program'; Value=(Get-SafeProperty $item 'AuditProgram') }
                @{ Name='AccountingSoftware1'; Type='text'; Label='Accounting Software 1'; Value=(Get-SafeProperty $item 'AccountingSoftware1') }
                @{ Name='AccountingSoftware1Other'; Type='text'; Label='Accounting Software 1 Other'; Value=(Get-SafeProperty $item 'AccountingSoftware1Other') }
                @{ Name='AccountingSoftware1Type'; Type='text'; Label='Accounting Software 1 Type'; Value=(Get-SafeProperty $item 'AccountingSoftware1Type') }
                @{ Name='AccountingSoftware2'; Type='text'; Label='Accounting Software 2'; Value=(Get-SafeProperty $item 'AccountingSoftware2') }
                @{ Name='AccountingSoftware2Other'; Type='text'; Label='Accounting Software 2 Other'; Value=(Get-SafeProperty $item 'AccountingSoftware2Other') }
                @{ Name='AccountingSoftware2Type'; Type='text'; Label='Accounting Software 2 Type'; Value=(Get-SafeProperty $item 'AccountingSoftware2Type') }
                @{ Name='Comments'; Type='text'; Label='Comments'; Value=(Get-SafeProperty $item 'Comments') }

                # Additional (2 fields)
                @{ Name='FXInfo'; Type='text'; Label='FX Info'; Value=(Get-SafeProperty $item 'FXInfo') }
                @{ Name='ShipToAddress'; Type='text'; Label='Ship To Address'; Value=(Get-SafeProperty $item 'ShipToAddress') }
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

            # Helper to parse array fields
            $parseArrayField = {
                param($fieldName)
                if ($values.ContainsKey($fieldName) -and $values.$fieldName -and $values.$fieldName.Trim()) {
                    return @($values.$fieldName -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
                }
                return @()
            }

            # Parse tags
            $tags = & $parseArrayField 'tags'

            # Helper to format dates
            $formatDate = {
                param($fieldName)
                if ($values.ContainsKey($fieldName) -and $values.$fieldName -is [DateTime]) {
                    return $values.$fieldName.ToString('yyyy-MM-dd')
                }
                return ''
            }

            # Check for duplicate project name before creating
            $existingProjects = $this.Store.GetAllProjects()

            $projectData = @{
                id = [guid]::NewGuid().ToString()
                name = $values.name
                description = if ($values.ContainsKey('description')) { $values.description } else { '' }
                created = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
                status = if ($values.ContainsKey('status')) { $values.status } else { 'active' }
                tags = $tags

                # ID fields
                ID1 = if ($values.ContainsKey('ID1')) { $values.ID1 } else { '' }
                ID2 = if ($values.ContainsKey('ID2')) { $values.ID2 } else { '' }

                # Path fields
                ProjFolder = if ($values.ContainsKey('ProjFolder')) { $values.ProjFolder } else { '' }
                CAAName = if ($values.ContainsKey('CAAName')) { $values.CAAName } else { '' }
                RequestName = if ($values.ContainsKey('RequestName')) { $values.RequestName } else { '' }
                T2020 = if ($values.ContainsKey('T2020')) { $values.T2020 } else { '' }

                # Date fields
                AssignedDate = & $formatDate 'AssignedDate'
                DueDate = & $formatDate 'DueDate'
                BFDate = & $formatDate 'BFDate'

                # Project Info (9 fields)
                RequestDate = & $formatDate 'RequestDate'
                AuditType = if ($values.ContainsKey('AuditType')) { $values.AuditType } else { '' }
                AuditorName = if ($values.ContainsKey('AuditorName')) { $values.AuditorName } else { '' }
                AuditorPhone = if ($values.ContainsKey('AuditorPhone')) { $values.AuditorPhone } else { '' }
                AuditorTL = if ($values.ContainsKey('AuditorTL')) { $values.AuditorTL } else { '' }
                AuditorTLPhone = if ($values.ContainsKey('AuditorTLPhone')) { $values.AuditorTLPhone } else { '' }
                AuditCase = if ($values.ContainsKey('AuditCase')) { $values.AuditCase } else { '' }
                CASCase = if ($values.ContainsKey('CASCase')) { $values.CASCase } else { '' }
                AuditStartDate = & $formatDate 'AuditStartDate'

                # Contact Details (10 fields)
                TPName = if ($values.ContainsKey('TPName')) { $values.TPName } else { '' }
                TPNum = if ($values.ContainsKey('TPNum')) { $values.TPNum } else { '' }
                Address = if ($values.ContainsKey('Address')) { $values.Address } else { '' }
                City = if ($values.ContainsKey('City')) { $values.City } else { '' }
                Province = if ($values.ContainsKey('Province')) { $values.Province } else { '' }
                PostalCode = if ($values.ContainsKey('PostalCode')) { $values.PostalCode } else { '' }
                Country = if ($values.ContainsKey('Country')) { $values.Country } else { '' }

                # Audit Periods (10 fields)
                AuditPeriodFrom = & $formatDate 'AuditPeriodFrom'
                AuditPeriodTo = & $formatDate 'AuditPeriodTo'
                AuditPeriod1Start = & $formatDate 'AuditPeriod1Start'
                AuditPeriod1End = & $formatDate 'AuditPeriod1End'
                AuditPeriod2Start = & $formatDate 'AuditPeriod2Start'
                AuditPeriod2End = & $formatDate 'AuditPeriod2End'
                AuditPeriod3Start = & $formatDate 'AuditPeriod3Start'
                AuditPeriod3End = & $formatDate 'AuditPeriod3End'
                AuditPeriod4Start = & $formatDate 'AuditPeriod4Start'
                AuditPeriod4End = & $formatDate 'AuditPeriod4End'
                AuditPeriod5Start = & $formatDate 'AuditPeriod5Start'
                AuditPeriod5End = & $formatDate 'AuditPeriod5End'

                # Contacts (10 fields)
                Contact1Name = if ($values.ContainsKey('Contact1Name')) { $values.Contact1Name } else { '' }
                Contact1Phone = if ($values.ContainsKey('Contact1Phone')) { $values.Contact1Phone } else { '' }
                Contact1Ext = if ($values.ContainsKey('Contact1Ext')) { $values.Contact1Ext } else { '' }
                Contact1Address = if ($values.ContainsKey('Contact1Address')) { $values.Contact1Address } else { '' }
                Contact1Title = if ($values.ContainsKey('Contact1Title')) { $values.Contact1Title } else { '' }
                Contact2Name = if ($values.ContainsKey('Contact2Name')) { $values.Contact2Name } else { '' }
                Contact2Phone = if ($values.ContainsKey('Contact2Phone')) { $values.Contact2Phone } else { '' }
                Contact2Ext = if ($values.ContainsKey('Contact2Ext')) { $values.Contact2Ext } else { '' }
                Contact2Address = if ($values.ContainsKey('Contact2Address')) { $values.Contact2Address } else { '' }
                Contact2Title = if ($values.ContainsKey('Contact2Title')) { $values.Contact2Title } else { '' }

                # System Info (7 fields)
                AuditProgram = if ($values.ContainsKey('AuditProgram')) { $values.AuditProgram } else { '' }
                AccountingSoftware1 = if ($values.ContainsKey('AccountingSoftware1')) { $values.AccountingSoftware1 } else { '' }
                AccountingSoftware1Other = if ($values.ContainsKey('AccountingSoftware1Other')) { $values.AccountingSoftware1Other } else { '' }
                AccountingSoftware1Type = if ($values.ContainsKey('AccountingSoftware1Type')) { $values.AccountingSoftware1Type } else { '' }
                AccountingSoftware2 = if ($values.ContainsKey('AccountingSoftware2')) { $values.AccountingSoftware2 } else { '' }
                AccountingSoftware2Other = if ($values.ContainsKey('AccountingSoftware2Other')) { $values.AccountingSoftware2Other } else { '' }
                AccountingSoftware2Type = if ($values.ContainsKey('AccountingSoftware2Type')) { $values.AccountingSoftware2Type } else { '' }
                Comments = if ($values.ContainsKey('Comments')) { $values.Comments } else { '' }

                # Additional (2 fields)
                FXInfo = if ($values.ContainsKey('FXInfo')) { $values.FXInfo } else { '' }
                ShipToAddress = if ($values.ContainsKey('ShipToAddress')) { $values.ShipToAddress } else { '' }
            }

            # Use ValidationHelper for comprehensive validation
            . "$PSScriptRoot/../helpers/ValidationHelper.ps1"
            $validationResult = Test-ProjectValid $projectData -existingProjects $existingProjects

            if (-not $validationResult.IsValid) {
                # Show ALL validation errors
                $errorMsg = if ($validationResult.Errors.Count -gt 0) {
                    $validationResult.Errors -join '; '
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

            # Helper to parse array fields
            $parseArrayField = {
                param($fieldName)
                if ($values.ContainsKey($fieldName) -and $values.$fieldName -and $values.$fieldName.Trim()) {
                    return @($values.$fieldName -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
                }
                return @()
            }

            # Parse tags
            $tags = & $parseArrayField 'tags'

            # Helper to format dates
            $formatDate = {
                param($fieldName)
                if ($values.ContainsKey($fieldName) -and $values.$fieldName -is [DateTime]) {
                    return $values.$fieldName.ToString('yyyy-MM-dd')
                }
                return ''
            }

            $changes = @{
                name = $values.name
                description = if ($values.ContainsKey('description')) { $values.description } else { '' }
                status = if ($values.ContainsKey('status')) { $values.status } else { '' }
                tags = $tags

                # ID fields
                ID1 = if ($values.ContainsKey('ID1')) { $values.ID1 } else { '' }
                ID2 = if ($values.ContainsKey('ID2')) { $values.ID2 } else { '' }

                # Path fields
                ProjFolder = if ($values.ContainsKey('ProjFolder')) { $values.ProjFolder } else { '' }
                CAAName = if ($values.ContainsKey('CAAName')) { $values.CAAName } else { '' }
                RequestName = if ($values.ContainsKey('RequestName')) { $values.RequestName } else { '' }
                T2020 = if ($values.ContainsKey('T2020')) { $values.T2020 } else { '' }

                # Date fields
                AssignedDate = & $formatDate 'AssignedDate'
                DueDate = & $formatDate 'DueDate'
                BFDate = & $formatDate 'BFDate'

                # Project Info (9 fields)
                RequestDate = & $formatDate 'RequestDate'
                AuditType = if ($values.ContainsKey('AuditType')) { $values.AuditType } else { '' }
                AuditorName = if ($values.ContainsKey('AuditorName')) { $values.AuditorName } else { '' }
                AuditorPhone = if ($values.ContainsKey('AuditorPhone')) { $values.AuditorPhone } else { '' }
                AuditorTL = if ($values.ContainsKey('AuditorTL')) { $values.AuditorTL } else { '' }
                AuditorTLPhone = if ($values.ContainsKey('AuditorTLPhone')) { $values.AuditorTLPhone } else { '' }
                AuditCase = if ($values.ContainsKey('AuditCase')) { $values.AuditCase } else { '' }
                CASCase = if ($values.ContainsKey('CASCase')) { $values.CASCase } else { '' }
                AuditStartDate = & $formatDate 'AuditStartDate'

                # Contact Details (10 fields)
                TPName = if ($values.ContainsKey('TPName')) { $values.TPName } else { '' }
                TPNum = if ($values.ContainsKey('TPNum')) { $values.TPNum } else { '' }
                Address = if ($values.ContainsKey('Address')) { $values.Address } else { '' }
                City = if ($values.ContainsKey('City')) { $values.City } else { '' }
                Province = if ($values.ContainsKey('Province')) { $values.Province } else { '' }
                PostalCode = if ($values.ContainsKey('PostalCode')) { $values.PostalCode } else { '' }
                Country = if ($values.ContainsKey('Country')) { $values.Country } else { '' }

                # Audit Periods (10 fields)
                AuditPeriodFrom = & $formatDate 'AuditPeriodFrom'
                AuditPeriodTo = & $formatDate 'AuditPeriodTo'
                AuditPeriod1Start = & $formatDate 'AuditPeriod1Start'
                AuditPeriod1End = & $formatDate 'AuditPeriod1End'
                AuditPeriod2Start = & $formatDate 'AuditPeriod2Start'
                AuditPeriod2End = & $formatDate 'AuditPeriod2End'
                AuditPeriod3Start = & $formatDate 'AuditPeriod3Start'
                AuditPeriod3End = & $formatDate 'AuditPeriod3End'
                AuditPeriod4Start = & $formatDate 'AuditPeriod4Start'
                AuditPeriod4End = & $formatDate 'AuditPeriod4End'
                AuditPeriod5Start = & $formatDate 'AuditPeriod5Start'
                AuditPeriod5End = & $formatDate 'AuditPeriod5End'

                # Contacts (10 fields)
                Contact1Name = if ($values.ContainsKey('Contact1Name')) { $values.Contact1Name } else { '' }
                Contact1Phone = if ($values.ContainsKey('Contact1Phone')) { $values.Contact1Phone } else { '' }
                Contact1Ext = if ($values.ContainsKey('Contact1Ext')) { $values.Contact1Ext } else { '' }
                Contact1Address = if ($values.ContainsKey('Contact1Address')) { $values.Contact1Address } else { '' }
                Contact1Title = if ($values.ContainsKey('Contact1Title')) { $values.Contact1Title } else { '' }
                Contact2Name = if ($values.ContainsKey('Contact2Name')) { $values.Contact2Name } else { '' }
                Contact2Phone = if ($values.ContainsKey('Contact2Phone')) { $values.Contact2Phone } else { '' }
                Contact2Ext = if ($values.ContainsKey('Contact2Ext')) { $values.Contact2Ext } else { '' }
                Contact2Address = if ($values.ContainsKey('Contact2Address')) { $values.Contact2Address } else { '' }
                Contact2Title = if ($values.ContainsKey('Contact2Title')) { $values.Contact2Title } else { '' }

                # System Info (7 fields)
                AuditProgram = if ($values.ContainsKey('AuditProgram')) { $values.AuditProgram } else { '' }
                AccountingSoftware1 = if ($values.ContainsKey('AccountingSoftware1')) { $values.AccountingSoftware1 } else { '' }
                AccountingSoftware1Other = if ($values.ContainsKey('AccountingSoftware1Other')) { $values.AccountingSoftware1Other } else { '' }
                AccountingSoftware1Type = if ($values.ContainsKey('AccountingSoftware1Type')) { $values.AccountingSoftware1Type } else { '' }
                AccountingSoftware2 = if ($values.ContainsKey('AccountingSoftware2')) { $values.AccountingSoftware2 } else { '' }
                AccountingSoftware2Other = if ($values.ContainsKey('AccountingSoftware2Other')) { $values.AccountingSoftware2Other } else { '' }
                AccountingSoftware2Type = if ($values.ContainsKey('AccountingSoftware2Type')) { $values.AccountingSoftware2Type } else { '' }
                Comments = if ($values.ContainsKey('Comments')) { $values.Comments } else { '' }

                # Additional (2 fields)
                FXInfo = if ($values.ContainsKey('FXInfo')) { $values.FXInfo } else { '' }
                ShipToAddress = if ($values.ContainsKey('ShipToAddress')) { $values.ShipToAddress } else { '' }
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
            # For now, recommend using ExcelImportScreen instead
            $this.SetStatusMessage("Excel import not implemented here. Use Tools > Import from Excel for full import wizard", "warning")
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
        # CRITICAL: Call parent FIRST for MenuBar, F10, Alt+keys
        $handled = ([PmcScreen]$this).HandleKeyPress($keyInfo)
        if ($handled) { return $true }

        # Handle custom project keys after menu bar

        # Custom key: V = View project details/stats
        if ($keyInfo.KeyChar -eq 'v' -or $keyInfo.KeyChar -eq 'V') {
            $selected = $this.List.GetSelectedItem()
            if ($selected) {
                try {
                    # Register ProjectInfoScreen in container if not already registered
                    if (-not $global:PmcContainer.IsRegistered('ProjectInfoScreen')) {
                        $screenPath = "$PSScriptRoot/ProjectInfoScreen.ps1"
                        $global:PmcContainer.Register('ProjectInfoScreen', {
                            param($c)
                            . $screenPath
                            return New-Object ProjectInfoScreen
                        }.GetNewClosure(), $false)
                    }

                    # Resolve screen from container (this handles all the loading)
                    $screen = $global:PmcContainer.Resolve('ProjectInfoScreen')
                    $projectName = Get-SafeProperty $selected 'name'
                    $screen.SetProject($projectName)
                    $global:PmcApp.PushScreen($screen)
                    $this.SetStatusMessage("Viewing project: $projectName", "success")
                } catch {
                    Write-PmcTuiLog "Failed to open ProjectInfoScreen: $_" "ERROR"
                    Write-PmcTuiLog "Stack trace: $($_.ScriptStackTrace)" "ERROR"
                    $this.SetStatusMessage("Failed to open project info: $($_.Exception.Message)", "error")
                }
            } else {
                $this.SetStatusMessage("No project selected", "error")
            }
            return $true
        }

        # Custom key: R = Archive/Unarchive
        if ($keyInfo.KeyChar -eq 'r' -or $keyInfo.KeyChar -eq 'R') {
            $selected = $this.List.GetSelectedItem()
            $this.ToggleProjectArchive($selected)
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

        # Call parent handler for list navigation, add/edit/delete
        $handled = ([StandardListScreen]$this).HandleKeyPress($keyInfo)
        if ($handled) { return $true }

        return $false
    }
}
