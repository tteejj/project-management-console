using namespace System.Collections.Generic
using namespace System.Text

# ProjectInfoScreen - Detailed project information
# Shows comprehensive details about a single project


Set-StrictMode -Version Latest

# PmcScreen is already loaded by Start-PmcTUI.ps1
# . "$PSScriptRoot/../PmcScreen.ps1"

<#
.SYNOPSIS
Project information screen showing detailed project data

.DESCRIPTION
Shows detailed information for a single project including:
- Project name and description
- Task counts (active/completed/total)
- Recent tasks
- Project metadata (status, created date, tags)
Supports:
- Editing project (E key)
- Deleting project (D key)
- Viewing tasks (T key)
#>
class ProjectInfoScreen : PmcScreen {
    # Data
    [string]$ProjectName = ""
    [object]$ProjectData = $null
    [array]$ProjectTasks = @()
    [hashtable]$ProjectStats = @{}
    [TaskStore]$Store = $null

    # Direct field editing
    [bool]$EditMode = $false
    [int]$SelectedFieldIndex = 0
    [string]$EditingValue = ""
    [bool]$IsEditingField = $false
    [array]$EditableFields = @()

    # Constructor
    ProjectInfoScreen() : base("ProjectInfo", "Project Information") {
        $this._InitializeScreen()
    }

    # Constructor with container
    ProjectInfoScreen([object]$container) : base("ProjectInfo", "Project Information", $container) {
        $this._InitializeScreen()
    }

    hidden [void] _InitializeScreen() {
        # Get TaskStore instance
        $this.Store = [TaskStore]::GetInstance()

        # Configure header
        $this.Header.SetBreadcrumb(@("Home", "Projects", "Info"))

        # Configure footer with shortcuts (will be updated dynamically based on mode)
        $this._UpdateFooterShortcuts()

        # NOTE: _SetupMenus() removed - MenuRegistry handles menu population via manifest
    }

    hidden [void] _UpdateFooterShortcuts() {
        $this.Footer.ClearShortcuts()
        if ($this.EditMode) {
            if ($this.IsEditingField) {
                $this.Footer.AddShortcut("Enter", "Save Field")
                $this.Footer.AddShortcut("Esc", "Cancel")
            } else {
                $this.Footer.AddShortcut("↑↓", "Navigate")
                $this.Footer.AddShortcut("Enter", "Edit Field")
                $this.Footer.AddShortcut("E", "Save & Exit")
                $this.Footer.AddShortcut("Esc", "Cancel")
            }
        } else {
            $this.Footer.AddShortcut("E", "Edit")
            $this.Footer.AddShortcut("N", "Notes")
            $this.Footer.AddShortcut("C", "Checklists")
            $this.Footer.AddShortcut("T", "Tasks")
            $this.Footer.AddShortcut("D", "Delete")
            $this.Footer.AddShortcut("Esc", "Back")
        }
    }

    [void] SetProject([string]$projectName) {
        $this.ProjectName = $projectName
    }

    # Override OnEnter to load data when screen is shown
    [void] OnEnter() {
        ([PmcScreen]$this).OnEnter()  # Call parent
        $this.LoadData()
    }

    [void] LoadData() {
        if ([string]::IsNullOrWhiteSpace($this.ProjectName)) {
            $this.ShowError("No project selected")
            return
        }

        $this.ShowStatus("Loading project information...")

        try {
            # Get all projects from TaskStore
            $allProjects = $this.Store.GetAllProjects()

            # Find project
            $this.ProjectData = $allProjects | Where-Object {
                ($_ -is [string] -and $_ -eq $this.ProjectName) -or
                ((Get-SafeProperty $_ 'name') -eq $this.ProjectName)
            } | Select-Object -First 1

            if (-not $this.ProjectData) {
                $this.ShowError("Project '$($this.ProjectName)' not found")
                return
            }

            # Get project tasks from TaskStore
            $allTasks = $this.Store.GetAllTasks()
            $this.ProjectTasks = @($allTasks | Where-Object { (Get-SafeProperty $_ 'project') -eq $this.ProjectName })

            # Calculate statistics
            $this.ProjectStats = @{
                TotalTasks = $this.ProjectTasks.Count
                ActiveTasks = @($this.ProjectTasks | Where-Object { (Get-SafeProperty $_ 'status') -ne 'completed' }).Count
                CompletedTasks = @($this.ProjectTasks | Where-Object { (Get-SafeProperty $_ 'status') -eq 'completed' }).Count
                OverdueTasks = 0
            }

            # Count overdue tasks
            $today = (Get-Date).Date
            foreach ($task in $this.ProjectTasks) {
                $taskStatus = Get-SafeProperty $task 'status'
                $taskDue = Get-SafeProperty $task 'due'
                if ($taskStatus -ne 'completed' -and $taskDue) {
                    try {
                        $dueDate = [DateTime]::Parse($taskDue)
                        if ($dueDate.Date -lt $today) {
                            $this.ProjectStats.OverdueTasks++
                        }
                    } catch {
                        if (Get-Command Write-PmcTuiLog -ErrorAction SilentlyContinue) {
                            Write-PmcTuiLog "Failed to parse due date '$taskDue' for task: $($_.Exception.Message)" "DEBUG"
                        }
                    }
                }
            }

            # Calculate completion percentage
            if ($this.ProjectStats.TotalTasks -gt 0) {
                $this.ProjectStats.CompletionPercent = [Math]::Round(
                    ($this.ProjectStats.CompletedTasks / $this.ProjectStats.TotalTasks) * 100, 1
                )
            } else {
                $this.ProjectStats.CompletionPercent = 0
            }

            $this.ShowSuccess("Loaded project: $($this.ProjectName)")

        } catch {
            $this.ShowError("Failed to load project: $_")
            $this.ProjectData = $null
            $this.ProjectTasks = @()
        }
    }

    [string] RenderContent() {
        # If editor is showing, render it instead
        if ($this.ShowEditor -and $this.Editor) {
            return $this.Editor.Render()
        }

        $sb = [System.Text.StringBuilder]::new(4096)

        if (-not $this.LayoutManager) {
            return $sb.ToString()
        }

        # Get content area
        $contentRect = $this.LayoutManager.GetRegion('Content', $this.TermWidth, $this.TermHeight)

        # Colors
        $textColor = $this.Header.GetThemedAnsi('Text', $false)
        $highlightColor = $this.Header.GetThemedAnsi('Highlight', $false)
        $mutedColor = $this.Header.GetThemedAnsi('Muted', $false)
        $headerColor = $this.Header.GetThemedAnsi('Muted', $false)
        $successColor = $this.Header.GetThemedAnsi('Success', $false)
        $warningColor = $this.Header.GetThemedAnsi('Warning', $false)
        $reset = "`e[0m"

        $y = $contentRect.Y + 1

        if (-not $this.ProjectData) {
            $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))
            $sb.Append($mutedColor)
            $sb.Append("No project loaded")
            $sb.Append($reset)
            return $sb.ToString()
        }

        # Compact header: Name, Status, Created on one line
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y++))
        $sb.Append($highlightColor)
        $name = if ($this.ProjectData -is [string]) { $this.ProjectData } else { Get-SafeProperty $this.ProjectData 'name' }
        $sb.Append($name)
        $sb.Append($reset)
        $sb.Append($mutedColor)
        $projectStatus = Get-SafeProperty $this.ProjectData 'status'
        if ($projectStatus) {
            $sb.Append(" | Status: ")
            $sb.Append($reset)
            $sb.Append($textColor)
            $sb.Append($projectStatus)
            $sb.Append($reset)
            $sb.Append($mutedColor)
        }
        $projectCreated = Get-SafeProperty $this.ProjectData 'created'
        if ($projectCreated) {
            $sb.Append(" | Created: ")
            $sb.Append($reset)
            $sb.Append($textColor)
            $sb.Append($projectCreated)
            $sb.Append($reset)
        }

        # All Project Fields (48 Excel fields)
        if ($this.ProjectData -isnot [string]) {
            $y++

            # In edit mode, display ONLY the editable fields with selection highlighting
            if ($this.EditMode) {
                $selectColor = "`e[30;47m"  # Black text on white background for selected field

                for ($i = 0; $i -lt $this.EditableFields.Count; $i++) {
                    $field = $this.EditableFields[$i]
                    $isSelected = ($i -eq $this.SelectedFieldIndex)

                    $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y))

                    # Apply selection highlight if this field is selected
                    if ($isSelected) {
                        $sb.Append($selectColor)
                        $sb.Append("> ")
                    } else {
                        $sb.Append($mutedColor)
                        $sb.Append("  ")
                    }

                    # Label
                    $label = $field.Label
                    if ($label.Length -gt 25) { $label = $label.Substring(0, 22) + "..." }
                    $sb.Append($label.PadRight(27))

                    if ($isSelected) {
                        $sb.Append($reset)
                        $sb.Append($highlightColor)
                    } else {
                        $sb.Append($reset)
                        $sb.Append($textColor)
                    }

                    # Value - if currently editing this field, show EditingValue
                    $val = if ($this.IsEditingField -and $isSelected) {
                        $this.EditingValue + "_"  # Show cursor
                    } elseif ($field.Value) {
                        $field.Value
                    } else {
                        $mutedColor + "(empty)" + $reset + $textColor
                    }

                    # Truncate value to fit
                    if ($val.Length -gt 50) { $val = $val.Substring(0, 47) + "..." }
                    $sb.Append($val)
                    $sb.Append($reset)

                    $y++
                }
            } else {
                # Normal view mode - show all 48 fields in 3 columns
                # Create array of all fields for display
                $fields = @(
                    @{Label="ID1"; Value=(Get-SafeProperty $this.ProjectData 'ID1')}
                    @{Label="ID2"; Value=(Get-SafeProperty $this.ProjectData 'ID2')}
                    @{Label="Project Folder"; Value=(Get-SafeProperty $this.ProjectData 'ProjFolder')}
                    @{Label="CAA Name"; Value=(Get-SafeProperty $this.ProjectData 'CAAName')}
                    @{Label="Request Name"; Value=(Get-SafeProperty $this.ProjectData 'RequestName')}
                    @{Label="T2020"; Value=(Get-SafeProperty $this.ProjectData 'T2020')}
                    @{Label="Assigned Date"; Value=(Get-SafeProperty $this.ProjectData 'AssignedDate')}
                    @{Label="Due Date"; Value=(Get-SafeProperty $this.ProjectData 'DueDate')}
                    @{Label="BF Date"; Value=(Get-SafeProperty $this.ProjectData 'BFDate')}
                    @{Label="Request Date"; Value=(Get-SafeProperty $this.ProjectData 'RequestDate')}
                    @{Label="Audit Type"; Value=(Get-SafeProperty $this.ProjectData 'AuditType')}
                    @{Label="Auditor Name"; Value=(Get-SafeProperty $this.ProjectData 'AuditorName')}
                    @{Label="Auditor Phone"; Value=(Get-SafeProperty $this.ProjectData 'AuditorPhone')}
                    @{Label="Auditor TL"; Value=(Get-SafeProperty $this.ProjectData 'AuditorTL')}
                    @{Label="Auditor TL Phone"; Value=(Get-SafeProperty $this.ProjectData 'AuditorTLPhone')}
                    @{Label="Audit Case"; Value=(Get-SafeProperty $this.ProjectData 'AuditCase')}
                    @{Label="CAS Case"; Value=(Get-SafeProperty $this.ProjectData 'CASCase')}
                    @{Label="Audit Start Date"; Value=(Get-SafeProperty $this.ProjectData 'AuditStartDate')}
                    @{Label="TP Name"; Value=(Get-SafeProperty $this.ProjectData 'TPName')}
                    @{Label="TP Number"; Value=(Get-SafeProperty $this.ProjectData 'TPNum')}
                    @{Label="Address"; Value=(Get-SafeProperty $this.ProjectData 'Address')}
                    @{Label="City"; Value=(Get-SafeProperty $this.ProjectData 'City')}
                    @{Label="Province"; Value=(Get-SafeProperty $this.ProjectData 'Province')}
                    @{Label="Postal Code"; Value=(Get-SafeProperty $this.ProjectData 'PostalCode')}
                    @{Label="Country"; Value=(Get-SafeProperty $this.ProjectData 'Country')}
                    @{Label="Audit Period From"; Value=(Get-SafeProperty $this.ProjectData 'AuditPeriodFrom')}
                    @{Label="Audit Period To"; Value=(Get-SafeProperty $this.ProjectData 'AuditPeriodTo')}
                    @{Label="Audit Period 1 Start"; Value=(Get-SafeProperty $this.ProjectData 'AuditPeriod1Start')}
                    @{Label="Audit Period 1 End"; Value=(Get-SafeProperty $this.ProjectData 'AuditPeriod1End')}
                    @{Label="Audit Period 2 Start"; Value=(Get-SafeProperty $this.ProjectData 'AuditPeriod2Start')}
                    @{Label="Audit Period 2 End"; Value=(Get-SafeProperty $this.ProjectData 'AuditPeriod2End')}
                    @{Label="Audit Period 3 Start"; Value=(Get-SafeProperty $this.ProjectData 'AuditPeriod3Start')}
                    @{Label="Audit Period 3 End"; Value=(Get-SafeProperty $this.ProjectData 'AuditPeriod3End')}
                    @{Label="Audit Period 4 Start"; Value=(Get-SafeProperty $this.ProjectData 'AuditPeriod4Start')}
                    @{Label="Audit Period 4 End"; Value=(Get-SafeProperty $this.ProjectData 'AuditPeriod4End')}
                    @{Label="Audit Period 5 Start"; Value=(Get-SafeProperty $this.ProjectData 'AuditPeriod5Start')}
                    @{Label="Audit Period 5 End"; Value=(Get-SafeProperty $this.ProjectData 'AuditPeriod5End')}
                    @{Label="Contact 1 Name"; Value=(Get-SafeProperty $this.ProjectData 'Contact1Name')}
                    @{Label="Contact 1 Phone"; Value=(Get-SafeProperty $this.ProjectData 'Contact1Phone')}
                    @{Label="Contact 1 Ext"; Value=(Get-SafeProperty $this.ProjectData 'Contact1Ext')}
                    @{Label="Contact 1 Address"; Value=(Get-SafeProperty $this.ProjectData 'Contact1Address')}
                    @{Label="Contact 1 Title"; Value=(Get-SafeProperty $this.ProjectData 'Contact1Title')}
                    @{Label="Contact 2 Name"; Value=(Get-SafeProperty $this.ProjectData 'Contact2Name')}
                    @{Label="Contact 2 Phone"; Value=(Get-SafeProperty $this.ProjectData 'Contact2Phone')}
                    @{Label="Contact 2 Ext"; Value=(Get-SafeProperty $this.ProjectData 'Contact2Ext')}
                    @{Label="Contact 2 Address"; Value=(Get-SafeProperty $this.ProjectData 'Contact2Address')}
                    @{Label="Contact 2 Title"; Value=(Get-SafeProperty $this.ProjectData 'Contact2Title')}
                    @{Label="Audit Program"; Value=(Get-SafeProperty $this.ProjectData 'AuditProgram')}
                    @{Label="Accounting Software 1"; Value=(Get-SafeProperty $this.ProjectData 'AccountingSoftware1')}
                    @{Label="Accounting Software 1 Other"; Value=(Get-SafeProperty $this.ProjectData 'AccountingSoftware1Other')}
                    @{Label="Accounting Software 1 Type"; Value=(Get-SafeProperty $this.ProjectData 'AccountingSoftware1Type')}
                    @{Label="Accounting Software 2"; Value=(Get-SafeProperty $this.ProjectData 'AccountingSoftware2')}
                    @{Label="Accounting Software 2 Other"; Value=(Get-SafeProperty $this.ProjectData 'AccountingSoftware2Other')}
                    @{Label="Accounting Software 2 Type"; Value=(Get-SafeProperty $this.ProjectData 'AccountingSoftware2Type')}
                    @{Label="Comments"; Value=(Get-SafeProperty $this.ProjectData 'Comments')}
                    @{Label="FX Info"; Value=(Get-SafeProperty $this.ProjectData 'FXInfo')}
                    @{Label="Ship To Address"; Value=(Get-SafeProperty $this.ProjectData 'ShipToAddress')}
                )

                # Display fields in three columns
                $colWidth = 42
                $col1X = $contentRect.X + 6
                $col2X = $col1X + $colWidth
                $col3X = $col2X + $colWidth

                for ($i = 0; $i -lt $fields.Count; $i += 3) {
                    # Column 1
                    $field1 = $fields[$i]
                    $sb.Append($this.Header.BuildMoveTo($col1X, $y))
                    $sb.Append($mutedColor)

                    # Truncate label if too long
                    $label1 = $field1.Label
                    if ($label1.Length -gt 20) { $label1 = $label1.Substring(0, 17) + "..." }

                    $sb.Append($label1.PadRight(22))
                    $sb.Append($reset)
                    $sb.Append($textColor)

                    $val1 = if ($field1.Value) { $field1.Value } else { $mutedColor + "(empty)" + $reset + $textColor }
                    # Truncate value to fit column
                    if ($val1.Length -gt 18) { $val1 = $val1.Substring(0, 15) + "..." }
                    $sb.Append($val1)
                    $sb.Append($reset)

                    # Column 2 (if exists)
                    if ($i + 1 -lt $fields.Count) {
                        $field2 = $fields[$i + 1]
                        $sb.Append($this.Header.BuildMoveTo($col2X, $y))
                        $sb.Append($mutedColor)

                        # Truncate label if too long
                        $label2 = $field2.Label
                        if ($label2.Length -gt 20) { $label2 = $label2.Substring(0, 17) + "..." }

                        $sb.Append($label2.PadRight(22))
                        $sb.Append($reset)
                        $sb.Append($textColor)

                        $val2 = if ($field2.Value) { $field2.Value } else { $mutedColor + "(empty)" + $reset + $textColor }
                        # Truncate value to fit column
                        if ($val2.Length -gt 18) { $val2 = $val2.Substring(0, 15) + "..." }
                        $sb.Append($val2)
                        $sb.Append($reset)
                    }

                    # Column 3 (if exists)
                    if ($i + 2 -lt $fields.Count) {
                        $field3 = $fields[$i + 2]
                        $sb.Append($this.Header.BuildMoveTo($col3X, $y))
                        $sb.Append($mutedColor)

                        # Truncate label if too long
                        $label3 = $field3.Label
                        if ($label3.Length -gt 20) { $label3 = $label3.Substring(0, 17) + "..." }

                        $sb.Append($label3.PadRight(22))
                        $sb.Append($reset)
                        $sb.Append($textColor)

                        $val3 = if ($field3.Value) { $field3.Value } else { $mutedColor + "(empty)" + $reset + $textColor }
                        # Truncate value to fit column
                        if ($val3.Length -gt 18) { $val3 = $val3.Substring(0, 15) + "..." }
                        $sb.Append($val3)
                        $sb.Append($reset)
                    }

                    $y++
                }
            }
        }

        # Compact task summary on one line
        $y++
        $sb.Append($this.Header.BuildMoveTo($contentRect.X + 4, $y++))
        $sb.Append($mutedColor)
        $sb.Append("Tasks: ")
        $sb.Append($reset)
        $sb.Append($textColor)
        $sb.Append($this.ProjectStats.TotalTasks)
        $sb.Append($mutedColor)
        $sb.Append(" total, ")
        $sb.Append($reset)
        $sb.Append($textColor)
        $sb.Append($this.ProjectStats.ActiveTasks)
        $sb.Append($mutedColor)
        $sb.Append(" active, ")
        $sb.Append($reset)
        $sb.Append($successColor)
        $sb.Append($this.ProjectStats.CompletedTasks)
        $sb.Append($mutedColor)
        $sb.Append(" completed")
        if ($this.ProjectStats.OverdueTasks -gt 0) {
            $sb.Append(", ")
            $sb.Append($reset)
            $sb.Append($warningColor)
            $sb.Append($this.ProjectStats.OverdueTasks)
            $sb.Append($mutedColor)
            $sb.Append(" overdue")
        }
        $sb.Append(" | ")
        $sb.Append($reset)
        $sb.Append($successColor)
        $sb.Append("$($this.ProjectStats.CompletionPercent)%")
        $sb.Append($mutedColor)
        $sb.Append(" complete")
        $sb.Append($reset)

        return $sb.ToString()
    }

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        # If editor is showing, route input to it
        if ($this.ShowEditor -and $this.Editor) {
            $handled = $this.Editor.HandleInput($keyInfo)
            # InlineEditor handles its own OnConfirmed/OnCancelled callbacks
            return $true
        }

        $keyChar = [char]::ToLower($keyInfo.KeyChar)
        $key = $keyInfo.Key

        # If currently editing a field, handle text input
        if ($this.IsEditingField) {
            if ($key -eq [ConsoleKey]::Enter) {
                # Save the edited value
                $this.EditableFields[$this.SelectedFieldIndex].Value = $this.EditingValue
                $this.IsEditingField = $false
                $this._UpdateFooterShortcuts()
                $this.ShowStatus("Field updated - Press E to save all changes")
                return $true
            }
            elseif ($key -eq [ConsoleKey]::Escape) {
                # Cancel editing this field
                $this.IsEditingField = $false
                $this.EditingValue = ""
                $this._UpdateFooterShortcuts()
                $this.ShowStatus("Edit cancelled")
                return $true
            }
            elseif ($key -eq [ConsoleKey]::Backspace) {
                # Remove last character
                if ($this.EditingValue.Length -gt 0) {
                    $this.EditingValue = $this.EditingValue.Substring(0, $this.EditingValue.Length - 1)
                }
                return $true
            }
            elseif (-not [char]::IsControl($keyInfo.KeyChar)) {
                # Add typed character to editing value
                $this.EditingValue += $keyInfo.KeyChar
                return $true
            }
            return $true
        }

        # In edit mode but not editing a specific field - handle navigation
        if ($this.EditMode) {
            if ($key -eq [ConsoleKey]::UpArrow) {
                # Move to previous field
                if ($this.SelectedFieldIndex -gt 0) {
                    $this.SelectedFieldIndex--
                }
                return $true
            }
            elseif ($key -eq [ConsoleKey]::DownArrow) {
                # Move to next field
                if ($this.SelectedFieldIndex -lt ($this.EditableFields.Count - 1)) {
                    $this.SelectedFieldIndex++
                }
                return $true
            }
            elseif ($key -eq [ConsoleKey]::Enter) {
                # Start editing the selected field
                $selectedField = $this.EditableFields[$this.SelectedFieldIndex]
                $this.EditingValue = if ($selectedField.Value) { $selectedField.Value } else { "" }
                $this.IsEditingField = $true
                $this._UpdateFooterShortcuts()
                $this.ShowStatus("Editing: $($selectedField.Label) - Enter to save, Esc to cancel")
                return $true
            }
            elseif ($keyChar -eq 'e') {
                # Save and exit edit mode
                $this._EditProject()
                return $true
            }
            elseif ($key -eq [ConsoleKey]::Escape) {
                # Exit edit mode without saving
                $this.EditMode = $false
                $this._UpdateFooterShortcuts()
                $this.ShowStatus("Edit mode cancelled")
                return $true
            }
            return $true
        }

        # Normal mode - handle standard commands
        # Handle Escape key
        if ($key -eq [ConsoleKey]::Escape) {
            $global:PmcApp.PopScreen()
            return $true
        }

        switch ($keyChar) {
            'e' {
                $this._EditProject()
                return $true
            }
            'n' {
                $this._ManageNotes()
                return $true
            }
            'c' {
                $this._ManageChecklists()
                return $true
            }
            'd' {
                $this._DeleteProject()
                return $true
            }
            't' {
                $this._ViewTasks()
                return $true
            }
            'r' {
                $this.LoadData()
                return $true
            }
        }

        return $false
    }

    # Get edit fields (same as ProjectListScreen)
    [array] GetEditFields() {
        if (-not $this.ProjectData -or $this.ProjectData -is [string]) {
            return @()
        }

        # Helper functions
        $arrayToStr = { param($arr) if ($arr -and $arr.Count -gt 0) { $arr -join ', ' } else { '' } }
        $formatDate = { param($field) $val = Get-SafeProperty $this.ProjectData $field; if ($val) { try { [DateTime]::Parse($val) } catch { $null } } else { $null } }

        # Return all 48 fields populated with current values
        return @(
            @{ Name='name'; Type='text'; Label='Project Name'; Required=$true; Value=(Get-SafeProperty $this.ProjectData 'name') }
            @{ Name='description'; Type='text'; Label='Description'; Value=(Get-SafeProperty $this.ProjectData 'description') }
            @{ Name='status'; Type='text'; Label='Status'; Value=(Get-SafeProperty $this.ProjectData 'status') }
            @{ Name='tags'; Type='text'; Label='Tags (comma-separated)'; Value=(& $arrayToStr (Get-SafeProperty $this.ProjectData 'tags')) }
            @{ Name='ID1'; Type='text'; Label='ID1'; Value=(Get-SafeProperty $this.ProjectData 'ID1') }
            @{ Name='ID2'; Type='text'; Label='ID2'; Value=(Get-SafeProperty $this.ProjectData 'ID2') }
            @{ Name='ProjFolder'; Type='text'; Label='Project Folder'; Value=(Get-SafeProperty $this.ProjectData 'ProjFolder') }
            @{ Name='CAAName'; Type='text'; Label='CAA Name'; Value=(Get-SafeProperty $this.ProjectData 'CAAName') }
            @{ Name='RequestName'; Type='text'; Label='Request Name'; Value=(Get-SafeProperty $this.ProjectData 'RequestName') }
            @{ Name='T2020'; Type='text'; Label='T2020'; Value=(Get-SafeProperty $this.ProjectData 'T2020') }
            @{ Name='AssignedDate'; Type='date'; Label='Assigned Date'; Value=(& $formatDate 'AssignedDate') }
            @{ Name='DueDate'; Type='date'; Label='Due Date'; Value=(& $formatDate 'DueDate') }
            @{ Name='BFDate'; Type='date'; Label='BF Date'; Value=(& $formatDate 'BFDate') }
            @{ Name='RequestDate'; Type='date'; Label='Request Date'; Value=(& $formatDate 'RequestDate') }
            @{ Name='AuditType'; Type='text'; Label='Audit Type'; Value=(Get-SafeProperty $this.ProjectData 'AuditType') }
            @{ Name='AuditorName'; Type='text'; Label='Auditor Name'; Value=(Get-SafeProperty $this.ProjectData 'AuditorName') }
            @{ Name='AuditorPhone'; Type='text'; Label='Auditor Phone'; Value=(Get-SafeProperty $this.ProjectData 'AuditorPhone') }
            @{ Name='AuditorTL'; Type='text'; Label='Auditor TL'; Value=(Get-SafeProperty $this.ProjectData 'AuditorTL') }
            @{ Name='AuditorTLPhone'; Type='text'; Label='Auditor TL Phone'; Value=(Get-SafeProperty $this.ProjectData 'AuditorTLPhone') }
            @{ Name='AuditCase'; Type='text'; Label='Audit Case'; Value=(Get-SafeProperty $this.ProjectData 'AuditCase') }
            @{ Name='CASCase'; Type='text'; Label='CAS Case'; Value=(Get-SafeProperty $this.ProjectData 'CASCase') }
            @{ Name='AuditStartDate'; Type='date'; Label='Audit Start Date'; Value=(& $formatDate 'AuditStartDate') }
            @{ Name='TPName'; Type='text'; Label='TP Name'; Value=(Get-SafeProperty $this.ProjectData 'TPName') }
            @{ Name='TPNum'; Type='text'; Label='TP Number'; Value=(Get-SafeProperty $this.ProjectData 'TPNum') }
            @{ Name='Address'; Type='text'; Label='Address'; Value=(Get-SafeProperty $this.ProjectData 'Address') }
            @{ Name='City'; Type='text'; Label='City'; Value=(Get-SafeProperty $this.ProjectData 'City') }
            @{ Name='Province'; Type='text'; Label='Province'; Value=(Get-SafeProperty $this.ProjectData 'Province') }
            @{ Name='PostalCode'; Type='text'; Label='Postal Code'; Value=(Get-SafeProperty $this.ProjectData 'PostalCode') }
            @{ Name='Country'; Type='text'; Label='Country'; Value=(Get-SafeProperty $this.ProjectData 'Country') }
            @{ Name='AuditPeriodFrom'; Type='date'; Label='Audit Period From'; Value=(& $formatDate 'AuditPeriodFrom') }
            @{ Name='AuditPeriodTo'; Type='date'; Label='Audit Period To'; Value=(& $formatDate 'AuditPeriodTo') }
            @{ Name='AuditPeriod1Start'; Type='date'; Label='Audit Period 1 Start'; Value=(& $formatDate 'AuditPeriod1Start') }
            @{ Name='AuditPeriod1End'; Type='date'; Label='Audit Period 1 End'; Value=(& $formatDate 'AuditPeriod1End') }
            @{ Name='AuditPeriod2Start'; Type='date'; Label='Audit Period 2 Start'; Value=(& $formatDate 'AuditPeriod2Start') }
            @{ Name='AuditPeriod2End'; Type='date'; Label='Audit Period 2 End'; Value=(& $formatDate 'AuditPeriod2End') }
            @{ Name='AuditPeriod3Start'; Type='date'; Label='Audit Period 3 Start'; Value=(& $formatDate 'AuditPeriod3Start') }
            @{ Name='AuditPeriod3End'; Type='date'; Label='Audit Period 3 End'; Value=(& $formatDate 'AuditPeriod3End') }
            @{ Name='AuditPeriod4Start'; Type='date'; Label='Audit Period 4 Start'; Value=(& $formatDate 'AuditPeriod4Start') }
            @{ Name='AuditPeriod4End'; Type='date'; Label='Audit Period 4 End'; Value=(& $formatDate 'AuditPeriod4End') }
            @{ Name='AuditPeriod5Start'; Type='date'; Label='Audit Period 5 Start'; Value=(& $formatDate 'AuditPeriod5Start') }
            @{ Name='AuditPeriod5End'; Type='date'; Label='Audit Period 5 End'; Value=(& $formatDate 'AuditPeriod5End') }
            @{ Name='Contact1Name'; Type='text'; Label='Contact 1 Name'; Value=(Get-SafeProperty $this.ProjectData 'Contact1Name') }
            @{ Name='Contact1Phone'; Type='text'; Label='Contact 1 Phone'; Value=(Get-SafeProperty $this.ProjectData 'Contact1Phone') }
            @{ Name='Contact1Ext'; Type='text'; Label='Contact 1 Ext'; Value=(Get-SafeProperty $this.ProjectData 'Contact1Ext') }
            @{ Name='Contact1Address'; Type='text'; Label='Contact 1 Address'; Value=(Get-SafeProperty $this.ProjectData 'Contact1Address') }
            @{ Name='Contact1Title'; Type='text'; Label='Contact 1 Title'; Value=(Get-SafeProperty $this.ProjectData 'Contact1Title') }
            @{ Name='Contact2Name'; Type='text'; Label='Contact 2 Name'; Value=(Get-SafeProperty $this.ProjectData 'Contact2Name') }
            @{ Name='Contact2Phone'; Type='text'; Label='Contact 2 Phone'; Value=(Get-SafeProperty $this.ProjectData 'Contact2Phone') }
            @{ Name='Contact2Ext'; Type='text'; Label='Contact 2 Ext'; Value=(Get-SafeProperty $this.ProjectData 'Contact2Ext') }
            @{ Name='Contact2Address'; Type='text'; Label='Contact 2 Address'; Value=(Get-SafeProperty $this.ProjectData 'Contact2Address') }
            @{ Name='Contact2Title'; Type='text'; Label='Contact 2 Title'; Value=(Get-SafeProperty $this.ProjectData 'Contact2Title') }
            @{ Name='AuditProgram'; Type='text'; Label='Audit Program'; Value=(Get-SafeProperty $this.ProjectData 'AuditProgram') }
            @{ Name='AccountingSoftware1'; Type='text'; Label='Accounting Software 1'; Value=(Get-SafeProperty $this.ProjectData 'AccountingSoftware1') }
            @{ Name='AccountingSoftware1Other'; Type='text'; Label='Accounting Software 1 Other'; Value=(Get-SafeProperty $this.ProjectData 'AccountingSoftware1Other') }
            @{ Name='AccountingSoftware1Type'; Type='text'; Label='Accounting Software 1 Type'; Value=(Get-SafeProperty $this.ProjectData 'AccountingSoftware1Type') }
            @{ Name='AccountingSoftware2'; Type='text'; Label='Accounting Software 2'; Value=(Get-SafeProperty $this.ProjectData 'AccountingSoftware2') }
            @{ Name='AccountingSoftware2Other'; Type='text'; Label='Accounting Software 2 Other'; Value=(Get-SafeProperty $this.ProjectData 'AccountingSoftware2Other') }
            @{ Name='AccountingSoftware2Type'; Type='text'; Label='Accounting Software 2 Type'; Value=(Get-SafeProperty $this.ProjectData 'AccountingSoftware2Type') }
            @{ Name='Comments'; Type='text'; Label='Comments'; Value=(Get-SafeProperty $this.ProjectData 'Comments') }
            @{ Name='FXInfo'; Type='text'; Label='FX Info'; Value=(Get-SafeProperty $this.ProjectData 'FXInfo') }
            @{ Name='ShipToAddress'; Type='text'; Label='Ship To Address'; Value=(Get-SafeProperty $this.ProjectData 'ShipToAddress') }
        )
    }

    hidden [void] _EditProject() {
        if ($this.EditMode) {
            # Already in edit mode - save and exit
            $this._SaveAllEdits()
            $this.EditMode = $false
            $this._UpdateFooterShortcuts()
            $this.ShowStatus("Edit mode off - changes saved")
        } else {
            # Enter edit mode
            $this.EditMode = $true
            $this.SelectedFieldIndex = 0
            $this._BuildEditableFieldsList()
            $this._UpdateFooterShortcuts()
            $this.ShowStatus("Edit mode - Arrow keys to navigate, Enter to edit field, E to save & exit")
        }
    }

    hidden [void] _BuildEditableFieldsList() {
        # Build list of all editable fields
        $this.EditableFields = @(
            @{Name='name'; Label='Project Name'; Value=(Get-SafeProperty $this.ProjectData 'name')}
            @{Name='description'; Label='Description'; Value=(Get-SafeProperty $this.ProjectData 'description')}
            @{Name='status'; Label='Status'; Value=(Get-SafeProperty $this.ProjectData 'status')}
            @{Name='ID1'; Label='ID1'; Value=(Get-SafeProperty $this.ProjectData 'ID1')}
            @{Name='ID2'; Label='ID2'; Value=(Get-SafeProperty $this.ProjectData 'ID2')}
            @{Name='ProjFolder'; Label='Project Folder'; Value=(Get-SafeProperty $this.ProjectData 'ProjFolder')}
            @{Name='CAAName'; Label='CAA Name'; Value=(Get-SafeProperty $this.ProjectData 'CAAName')}
            @{Name='RequestName'; Label='Request Name'; Value=(Get-SafeProperty $this.ProjectData 'RequestName')}
            @{Name='T2020'; Label='T2020'; Value=(Get-SafeProperty $this.ProjectData 'T2020')}
            @{Name='TPName'; Label='TP Name'; Value=(Get-SafeProperty $this.ProjectData 'TPName')}
            @{Name='TPNum'; Label='TP Number'; Value=(Get-SafeProperty $this.ProjectData 'TPNum')}
            @{Name='Address'; Label='Address'; Value=(Get-SafeProperty $this.ProjectData 'Address')}
            @{Name='City'; Label='City'; Value=(Get-SafeProperty $this.ProjectData 'City')}
            @{Name='Province'; Label='Province'; Value=(Get-SafeProperty $this.ProjectData 'Province')}
            @{Name='PostalCode'; Label='Postal Code'; Value=(Get-SafeProperty $this.ProjectData 'PostalCode')}
            @{Name='Country'; Label='Country'; Value=(Get-SafeProperty $this.ProjectData 'Country')}
            @{Name='AuditType'; Label='Audit Type'; Value=(Get-SafeProperty $this.ProjectData 'AuditType')}
            @{Name='AuditorName'; Label='Auditor Name'; Value=(Get-SafeProperty $this.ProjectData 'AuditorName')}
            @{Name='AuditorPhone'; Label='Auditor Phone'; Value=(Get-SafeProperty $this.ProjectData 'AuditorPhone')}
            @{Name='AuditCase'; Label='Audit Case'; Value=(Get-SafeProperty $this.ProjectData 'AuditCase')}
            @{Name='Comments'; Label='Comments'; Value=(Get-SafeProperty $this.ProjectData 'Comments')}
        )
    }

    hidden [void] _SaveAllEdits() {
        # Save all modified fields back to project data
        $modified = $false
        foreach ($field in $this.EditableFields) {
            $currentValue = Get-SafeProperty $this.ProjectData $field.Name
            if ($field.Value -ne $currentValue) {
                $this.ProjectData[$field.Name] = $field.Value
                $modified = $true
            }
        }

        if ($modified) {
            $projectId = Get-SafeProperty $this.ProjectData 'id'
            $this.Store.UpdateProject($projectId, $this.ProjectData)
            $this.ShowSuccess("Project updated")
            $this.LoadData()
        }
    }

    hidden [void] _SaveProjectEdits([hashtable]$values) {
        try {
            # Convert tags string to array
            $tagsStr = if ($values.ContainsKey('tags')) { $values.tags } else { '' }
            $tags = if ($tagsStr) { $tagsStr -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ } } else { @() }

            # Helper to format dates
            $formatDate = {
                param($fieldName)
                $val = if ($values.ContainsKey($fieldName)) { $values[$fieldName] } else { $null }
                if ($val -and $val -is [DateTime]) {
                    return $val.ToString('yyyy-MM-dd')
                } elseif ($val) {
                    return $val
                } else {
                    return $null
                }
            }

            # Build updated project data
            $projectId = Get-SafeProperty $this.ProjectData 'id'
            $updatedProject = @{
                id = $projectId
                name = $values.name
                description = if ($values.ContainsKey('description')) { $values.description } else { '' }
                status = if ($values.ContainsKey('status')) { $values.status } else { 'active' }
                tags = $tags
                created = Get-SafeProperty $this.ProjectData 'created'

                # All 48 Excel fields
                ID1 = if ($values.ContainsKey('ID1')) { $values.ID1 } else { '' }
                ID2 = if ($values.ContainsKey('ID2')) { $values.ID2 } else { '' }
                ProjFolder = if ($values.ContainsKey('ProjFolder')) { $values.ProjFolder } else { '' }
                CAAName = if ($values.ContainsKey('CAAName')) { $values.CAAName } else { '' }
                RequestName = if ($values.ContainsKey('RequestName')) { $values.RequestName } else { '' }
                T2020 = if ($values.ContainsKey('T2020')) { $values.T2020 } else { '' }
                AssignedDate = & $formatDate 'AssignedDate'
                DueDate = & $formatDate 'DueDate'
                BFDate = & $formatDate 'BFDate'
                RequestDate = & $formatDate 'RequestDate'
                AuditType = if ($values.ContainsKey('AuditType')) { $values.AuditType } else { '' }
                AuditorName = if ($values.ContainsKey('AuditorName')) { $values.AuditorName } else { '' }
                AuditorPhone = if ($values.ContainsKey('AuditorPhone')) { $values.AuditorPhone } else { '' }
                AuditorTL = if ($values.ContainsKey('AuditorTL')) { $values.AuditorTL } else { '' }
                AuditorTLPhone = if ($values.ContainsKey('AuditorTLPhone')) { $values.AuditorTLPhone } else { '' }
                AuditCase = if ($values.ContainsKey('AuditCase')) { $values.AuditCase } else { '' }
                CASCase = if ($values.ContainsKey('CASCase')) { $values.CASCase } else { '' }
                AuditStartDate = & $formatDate 'AuditStartDate'
                TPName = if ($values.ContainsKey('TPName')) { $values.TPName } else { '' }
                TPNum = if ($values.ContainsKey('TPNum')) { $values.TPNum } else { '' }
                Address = if ($values.ContainsKey('Address')) { $values.Address } else { '' }
                City = if ($values.ContainsKey('City')) { $values.City } else { '' }
                Province = if ($values.ContainsKey('Province')) { $values.Province } else { '' }
                PostalCode = if ($values.ContainsKey('PostalCode')) { $values.PostalCode } else { '' }
                Country = if ($values.ContainsKey('Country')) { $values.Country } else { '' }
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
                AuditProgram = if ($values.ContainsKey('AuditProgram')) { $values.AuditProgram } else { '' }
                AccountingSoftware1 = if ($values.ContainsKey('AccountingSoftware1')) { $values.AccountingSoftware1 } else { '' }
                AccountingSoftware1Other = if ($values.ContainsKey('AccountingSoftware1Other')) { $values.AccountingSoftware1Other } else { '' }
                AccountingSoftware1Type = if ($values.ContainsKey('AccountingSoftware1Type')) { $values.AccountingSoftware1Type } else { '' }
                AccountingSoftware2 = if ($values.ContainsKey('AccountingSoftware2')) { $values.AccountingSoftware2 } else { '' }
                AccountingSoftware2Other = if ($values.ContainsKey('AccountingSoftware2Other')) { $values.AccountingSoftware2Other } else { '' }
                AccountingSoftware2Type = if ($values.ContainsKey('AccountingSoftware2Type')) { $values.AccountingSoftware2Type } else { '' }
                Comments = if ($values.ContainsKey('Comments')) { $values.Comments } else { '' }
                FXInfo = if ($values.ContainsKey('FXInfo')) { $values.FXInfo } else { '' }
                ShipToAddress = if ($values.ContainsKey('ShipToAddress')) { $values.ShipToAddress } else { '' }
            }

            # Update via TaskStore
            $this.Store.UpdateProject($projectId, $updatedProject)
            $this.ShowSuccess("Project updated: $($values.name)")

            # Reload data to reflect changes
            $this.LoadData()

        } catch {
            $this.ShowError("Failed to save project: $($_.Exception.Message)")
            Write-PmcTuiLog "Failed to save project edits: $_" "ERROR"
        }
    }

    hidden [void] _DeleteProject() {
        # Confirm and delete project
        $allProjects = $this.Store.GetAllProjects()
        $project = $allProjects | Where-Object { (Get-SafeProperty $_ 'name') -eq $this.ProjectName }

        if ($project) {
            # Count tasks in this project
            $allTasks = $this.Store.GetAllTasks()
            $taskCount = ($allTasks | Where-Object { (Get-SafeProperty $_ 'project') -eq $this.ProjectName }).Count

            if ($taskCount -gt 0) {
                $this.ShowError("Cannot delete project with $taskCount tasks. Move or delete tasks first.")
            } else {
                # Delete project using TaskStore
                $projectId = Get-SafeProperty $project 'id'
                if ($projectId) {
                    $this.Store.DeleteProject($projectId)
                    $this.ShowSuccess("Project deleted: $($this.ProjectName)")
                    $global:PmcApp.PopScreen()
                } else {
                    $this.ShowError("Cannot delete project: Project ID not found")
                }
            }
        }
    }

    hidden [void] _ViewTasks() {
        $this.ShowStatus("Viewing tasks for: $($this.ProjectName)")
        # In a real implementation, would navigate to filtered task list
    }

    hidden [void] _ManageNotes() {
        $this.ShowStatus("Opening notes for project: $($this.ProjectName)")

        # Get project ID for owner context
        $projectId = if ($this.ProjectData -and $this.ProjectData -isnot [string]) {
            Get-SafeProperty $this.ProjectData 'id'
        } else {
            $null
        }

        if (-not $projectId) {
            $this.ShowError("Cannot open notes: Project ID not found")
            return
        }

        # Load and open NotesMenuScreen with project owner context
        if (Test-Path "$PSScriptRoot/NotesMenuScreen.ps1") {
            . "$PSScriptRoot/NotesMenuScreen.ps1"
            # Pass owner context: ownerType="project", ownerId=projectId, ownerName=projectName
            # This filters notes to show ONLY this project's notes and auto-links new notes to this project
            $notesScreen = New-Object NotesMenuScreen "project", $projectId, $this.ProjectName
            $global:PmcApp.PushScreen($notesScreen)
        } else {
            $this.ShowError("Notes feature not available")
        }
    }

    hidden [void] _ManageChecklists() {
        $this.ShowStatus("Opening checklists for project: $($this.ProjectName)")

        # Get project ID for owner context
        $projectId = if ($this.ProjectData -and $this.ProjectData -isnot [string]) {
            Get-SafeProperty $this.ProjectData 'id'
        } else {
            $null
        }

        if (-not $projectId) {
            $this.ShowError("Cannot open checklists: Project ID not found")
            return
        }

        # Load and open ChecklistsMenuScreen (NOT ChecklistTemplatesScreen) with project owner context
        if (Test-Path "$PSScriptRoot/ChecklistsMenuScreen.ps1") {
            . "$PSScriptRoot/ChecklistsMenuScreen.ps1"
            # Pass owner context: ownerType="project", ownerId=projectId, ownerName=projectName
            # This shows ONLY this project's checklists and auto-links new checklists to this project
            $checklistScreen = New-Object ChecklistsMenuScreen "project", $projectId, $this.ProjectName
            $global:PmcApp.PushScreen($checklistScreen)
        } else {
            $this.ShowError("Checklist feature not available")
        }
    }
}

# Entry point function for compatibility
function Show-ProjectInfoScreen {
    param(
        [object]$App,
        [string]$ProjectName
    )

    if (-not $App) {
        throw "PmcApplication required"
    }

    $screen = [ProjectInfoScreen]::new()
    if ($ProjectName) {
        $screen.SetProject($ProjectName)
    }
    $App.PushScreen($screen)
}
