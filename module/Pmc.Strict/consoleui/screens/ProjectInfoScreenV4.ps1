# ProjectInfoScreenV4.ps1 - Tabbed interface for project details
#
# Clean implementation using TabbedScreen base class
# Organizes 57 fields into 6 logical tabs:
# - Identity (4 fields)
# - Request (6 fields)
# - Audit (8 fields)
# - Location (7 fields)
# - Periods (12 fields)
# - More (20 fields - contacts, software, misc)

using namespace System.Collections.Generic
using namespace System.Text

Set-StrictMode -Version Latest

# Load dependencies
. "$PSScriptRoot/../base/TabbedScreen.ps1"

<#
.SYNOPSIS
Project information screen with tabbed interface

.DESCRIPTION
Displays and edits all project fields organized into 6 tabs:
- Identity: IDs, folder, CAA name
- Request: Request details and dates
- Audit: Auditor information and cases
- Location: Third party and address
- Periods: Audit period date ranges
- More: Contacts, software, comments

Navigation:
- Tab/Shift+Tab: Cycle through tabs
- 1-6: Jump to specific tab
- Up/Down: Navigate fields
- Enter: Edit current field
- S: Save all changes

.PARAMETER projectName
Name of project to display
#>
class ProjectInfoScreenV4 : TabbedScreen {
    # === Data ===
    [string]$ProjectName = ""
    [hashtable]$ProjectData = @{}
    [object]$Store = $null

    # === Constructor ===
    ProjectInfoScreenV4([string]$projectName) : base("ProjectInfo", "Project Information") {
        $this.ProjectName = $projectName
        $this.Store = [TaskStore]::GetInstance()
        $this._UpdateBreadcrumb()
    }

    # Constructor with container
    ProjectInfoScreenV4([object]$container) : base("ProjectInfo", "Project Information", $container) {
        $this.Store = $container.Resolve('TaskStore')
        $this._UpdateBreadcrumb()
    }

    [void] SetProject([string]$projectName) {
        $this.ProjectName = $projectName
        $this._UpdateBreadcrumb()
    }

    hidden [void] _UpdateBreadcrumb() {
        if ($this.Header) {
            $name = if ($this.ProjectName) { $this.ProjectName } else { "Select Project" }
            $this.Header.SetBreadcrumb(@("Home", "Projects", $name))
        }
    }

    # === Data Loading ===

    [void] LoadData() {
        if ([string]::IsNullOrWhiteSpace($this.ProjectName)) {
            if ($this.StatusBar) {
                $this.StatusBar.SetLeftText("No project selected")
                $this.StatusBar.SetRightText("")
            }
            $this.ProjectData = @{}
            $this._BuildTabs()
            return
        }

        # Load project data from store
        $project = $this.Store.GetProject($this.ProjectName)

        if ($null -eq $project) {
            if ($this.StatusBar) {
                $this.StatusBar.SetRightText("Project not found: $($this.ProjectName)")
            }
            $this.ProjectData = @{}
            $this._BuildTabs()
            return
        }

        $this.ProjectData = $project

        # Build tabs with current data
        $this._BuildTabs()

        if ($this.StatusBar) {
            $this.StatusBar.SetLeftText("Project: $($this.ProjectName)")
        }
    }

    hidden [object] _GetValue([string]$key) {
        if ($this.ProjectData.PSObject.Properties[$key]) {
            return $this.ProjectData.$key
        }
        return $null
    }

    hidden [void] _BuildTabs() {
        # Clear existing tabs
        $this.TabPanel.Tabs.Clear()

        # Tab 1: Identity
        $this.TabPanel.AddTab('Identity', @(
            @{Name='ID1'; Label='ID1'; Value=$this._GetValue('ID1'); Type='text'}
            @{Name='ID2'; Label='ID2'; Value=$this._GetValue('ID2'); Type='text'}
            @{Name='ProjFolder'; Label='Project Folder'; Value=$this._GetValue('ProjFolder'); Type='text'}
            @{Name='CAAName'; Label='CAA Name'; Value=$this._GetValue('CAAName'); Type='text'}
        ))

        # Tab 2: Request
        $this.TabPanel.AddTab('Request', @(
            @{Name='RequestName'; Label='Request Name'; Value=$this._GetValue('RequestName'); Type='text'}
            @{Name='T2020'; Label='T2020'; Value=$this._GetValue('T2020'); Type='text'}
            @{Name='AssignedDate'; Label='Assigned Date'; Value=$this._GetValue('AssignedDate'); Type='date'}
            @{Name='DueDate'; Label='Due Date'; Value=$this._GetValue('DueDate'); Type='date'}
            @{Name='BFDate'; Label='BF Date'; Value=$this._GetValue('BFDate'); Type='date'}
            @{Name='RequestDate'; Label='Request Date'; Value=$this._GetValue('RequestDate'); Type='date'}
        ))

        # Tab 3: Audit
        $this.TabPanel.AddTab('Audit', @(
            @{Name='AuditType'; Label='Audit Type'; Value=$this._GetValue('AuditType'); Type='text'}
            @{Name='AuditorName'; Label='Auditor Name'; Value=$this._GetValue('AuditorName'); Type='text'}
            @{Name='AuditorPhone'; Label='Auditor Phone'; Value=$this._GetValue('AuditorPhone'); Type='text'}
            @{Name='AuditorTL'; Label='Auditor Team Lead'; Value=$this._GetValue('AuditorTL'); Type='text'}
            @{Name='AuditorTLPhone'; Label='TL Phone'; Value=$this._GetValue('AuditorTLPhone'); Type='text'}
            @{Name='AuditCase'; Label='Audit Case'; Value=$this._GetValue('AuditCase'); Type='text'}
            @{Name='CASCase'; Label='CAS Case'; Value=$this._GetValue('CASCase'); Type='text'}
            @{Name='AuditStartDate'; Label='Audit Start Date'; Value=$this._GetValue('AuditStartDate'); Type='date'}
        ))

        # Tab 4: Location
        $this.TabPanel.AddTab('Location', @(
            @{Name='TPName'; Label='Third Party Name'; Value=$this._GetValue('TPName'); Type='text'}
            @{Name='TPNum'; Label='Third Party Number'; Value=$this._GetValue('TPNum'); Type='text'}
            @{Name='Address'; Label='Address'; Value=$this._GetValue('Address'); Type='text'}
            @{Name='City'; Label='City'; Value=$this._GetValue('City'); Type='text'}
            @{Name='Province'; Label='Province'; Value=$this._GetValue('Province'); Type='text'}
            @{Name='PostalCode'; Label='Postal Code'; Value=$this._GetValue('PostalCode'); Type='text'}
            @{Name='Country'; Label='Country'; Value=$this._GetValue('Country'); Type='text'}
        ))

        # Tab 5: Periods
        $this.TabPanel.AddTab('Periods', @(
            @{Name='AuditPeriodFrom'; Label='Audit Period From'; Value=$this._GetValue('AuditPeriodFrom'); Type='date'}
            @{Name='AuditPeriodTo'; Label='Audit Period To'; Value=$this._GetValue('AuditPeriodTo'); Type='date'}
            @{Name='Period1Start'; Label='Period 1 Start'; Value=$this._GetValue('Period1Start'); Type='date'}
            @{Name='Period1End'; Label='Period 1 End'; Value=$this._GetValue('Period1End'); Type='date'}
            @{Name='Period2Start'; Label='Period 2 Start'; Value=$this._GetValue('Period2Start'); Type='date'}
            @{Name='Period2End'; Label='Period 2 End'; Value=$this._GetValue('Period2End'); Type='date'}
            @{Name='Period3Start'; Label='Period 3 Start'; Value=$this._GetValue('Period3Start'); Type='date'}
            @{Name='Period3End'; Label='Period 3 End'; Value=$this._GetValue('Period3End'); Type='date'}
            @{Name='Period4Start'; Label='Period 4 Start'; Value=$this._GetValue('Period4Start'); Type='date'}
            @{Name='Period4End'; Label='Period 4 End'; Value=$this._GetValue('Period4End'); Type='date'}
            @{Name='Period5Start'; Label='Period 5 Start'; Value=$this._GetValue('Period5Start'); Type='date'}
            @{Name='Period5End'; Label='Period 5 End'; Value=$this._GetValue('Period5End'); Type='date'}
        ))

        # Tab 6: More (Contacts, Software, Misc)
        $this.TabPanel.AddTab('More', @(
            # Contact 1
            @{Name='Contact1Name'; Label='Contact 1 Name'; Value=$this._GetValue('Contact1Name'); Type='text'}
            @{Name='Contact1Title'; Label='Contact 1 Title'; Value=$this._GetValue('Contact1Title'); Type='text'}
            @{Name='Contact1Phone'; Label='Contact 1 Phone'; Value=$this._GetValue('Contact1Phone'); Type='text'}
            @{Name='Contact1Email'; Label='Contact 1 Email'; Value=$this._GetValue('Contact1Email'); Type='text'}
            @{Name='Contact1Fax'; Label='Contact 1 Fax'; Value=$this._GetValue('Contact1Fax'); Type='text'}
            # Contact 2
            @{Name='Contact2Name'; Label='Contact 2 Name'; Value=$this._GetValue('Contact2Name'); Type='text'}
            @{Name='Contact2Title'; Label='Contact 2 Title'; Value=$this._GetValue('Contact2Title'); Type='text'}
            @{Name='Contact2Phone'; Label='Contact 2 Phone'; Value=$this._GetValue('Contact2Phone'); Type='text'}
            @{Name='Contact2Email'; Label='Contact 2 Email'; Value=$this._GetValue('Contact2Email'); Type='text'}
            @{Name='Contact2Fax'; Label='Contact 2 Fax'; Value=$this._GetValue('Contact2Fax'); Type='text'}
            # Software 1
            @{Name='Software1Name'; Label='Software 1 Name'; Value=$this._GetValue('Software1Name'); Type='text'}
            @{Name='Software1Version'; Label='Software 1 Version'; Value=$this._GetValue('Software1Version'); Type='text'}
            @{Name='Software1Vendor'; Label='Software 1 Vendor'; Value=$this._GetValue('Software1Vendor'); Type='text'}
            # Software 2
            @{Name='Software2Name'; Label='Software 2 Name'; Value=$this._GetValue('Software2Name'); Type='text'}
            @{Name='Software2Version'; Label='Software 2 Version'; Value=$this._GetValue('Software2Version'); Type='text'}
            @{Name='Software2Vendor'; Label='Software 2 Vendor'; Value=$this._GetValue('Software2Vendor'); Type='text'}
            # Misc
            @{Name='AuditProgram'; Label='Audit Program'; Value=$this._GetValue('AuditProgram'); Type='text'}
            @{Name='Comments'; Label='Comments'; Value=$this._GetValue('Comments'); Type='text'}
            @{Name='FXInfo'; Label='FX Info'; Value=$this._GetValue('FXInfo'); Type='text'}
            @{Name='ShipToAddress'; Label='Ship To Address'; Value=$this._GetValue('ShipToAddress'); Type='text'}
        ))
    }

    # === Saving ===

    [void] SaveChanges() {
        # Get all field values from TabPanel
        $values = $this.TabPanel.GetAllValues()

        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] ProjectInfoScreenV4.SaveChanges: Saving project '$($this.ProjectName)' with $($values.Count) fields"
        }

        # Update project in store (this updates in-memory but doesn't persist)
        $success = $this.Store.UpdateProject($this.ProjectName, $values)

        if ($success) {
            # FORCE persist to disk
            if (-not $this.Store.SaveData()) {
                if ($this.StatusBar) {
                    $this.StatusBar.SetRightText("Save to disk failed")
                }
                if ($global:PmcTuiLogFile) {
                    Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] ProjectInfoScreenV4.SaveChanges: SaveData FAILED"
                }
                return
            }

            # Update status
            if ($this.StatusBar) {
                $this.StatusBar.SetRightText("Saved")
            }
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] ProjectInfoScreenV4.SaveChanges: Save successful and persisted to disk"
            }
        } else {
            if ($this.StatusBar) {
                $this.StatusBar.SetRightText("Save failed: $($this.Store.LastError)")
            }
            if ($global:PmcTuiLogFile) {
                Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] ProjectInfoScreenV4.SaveChanges: UpdateProject FAILED - $($this.Store.LastError)"
            }
        }
    }

    # === Event Handlers ===

    [void] OnTabChanged([int]$tabIndex) {
        # Call base implementation
        ([TabbedScreen]$this).OnTabChanged($tabIndex)

        # Custom handling - could add tab-specific logic here
    }

    [void] OnFieldEdited($field, $newValue) {
        # Auto-save on each field edit
        if ($global:PmcTuiLogFile) {
            Add-Content -Path $global:PmcTuiLogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] ProjectInfoScreenV4.OnFieldEdited: field=$($field.Name) value='$newValue' - auto-saving"
        }
        $this.SaveChanges()
        # $this.SaveChanges()

        # Or just log the change
        Write-PmcTuiLog "Field '$($field.Name)' changed to: $newValue" "DEBUG"
    }
}

# Export
Export-ModuleMember -Variable @()
