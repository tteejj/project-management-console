# TabbedScreen.ps1 - Base class for screens using tabbed interface
#
# Usage:
#   class MyScreen : TabbedScreen {
#       MyScreen() : base("MyScreen", "My Title") {
#           $this._InitializeTabs()
#       }
#
#       hidden [void] _InitializeTabs() {
#           $this.TabPanel.AddTab('General', $this.GetGeneralFields())
#           $this.TabPanel.AddTab('Details', $this.GetDetailFields())
#       }
#
#       [array] GetGeneralFields() {
#           return @(
#               @{Name='name'; Label='Name'; Value=$this.Data.name}
#               @{Name='email'; Label='Email'; Value=$this.Data.email}
#           )
#       }
#
#       [void] SaveChanges() {
#           $values = $this.TabPanel.GetAllValues()
#           # Save to store
#       }
#   }

using namespace System.Collections.Generic
using namespace System.Text

Set-StrictMode -Version Latest

# Load dependencies
if (-not ([System.Management.Automation.PSTypeName]'PmcScreen').Type) {
    . "$PSScriptRoot/../PmcScreen.ps1"
}

if (-not ([System.Management.Automation.PSTypeName]'TabPanel').Type) {
    . "$PSScriptRoot/../widgets/TabPanel.ps1"
}

if (-not ([System.Management.Automation.PSTypeName]'InlineEditor').Type) {
    . "$PSScriptRoot/../widgets/InlineEditor.ps1"
}

<#
.SYNOPSIS
Base class for screens using tabbed interface to organize many fields

.DESCRIPTION
TabbedScreen provides a complete tabbed interface experience:
- TabPanel widget for tab navigation
- InlineEditor for field editing (vertical popup mode)
- Automatic keyboard navigation (Tab, arrows, numbers)
- Edit mode with save/cancel
- Theme integration
- Extensible via abstract methods

Abstract Methods (override in subclasses):
- LoadData() - Load data for fields
- SaveChanges() - Save field values

Optional Overrides:
- OnTabChanged($tabIndex) - Handle tab change
- OnFieldSelected($field) - Handle field selection
- OnFieldEdited($field, $newValue) - Handle field edit

.EXAMPLE
class SettingsScreen : TabbedScreen {
    SettingsScreen() : base("Settings", "Application Settings") {
        $this.TabPanel.AddTab('General', @(
            @{Name='theme'; Label='Theme'; Value='dark'}
            @{Name='fontSize'; Label='Font Size'; Value=12}
        ))
        $this.TabPanel.AddTab('Advanced', @(...))
    }

    [void] SaveChanges() {
        $values = $this.TabPanel.GetAllValues()
        $this.Store.UpdateSettings($values)
    }
}
#>
class TabbedScreen : PmcScreen {
    # === Core Components ===
    [TabPanel]$TabPanel = $null
    [InlineEditor]$InlineEditor = $null

    # === Component State ===
    [bool]$ShowEditor = $false
    [object]$CurrentEditField = $null

    # === Constructor (no container) ===
    TabbedScreen([string]$key, [string]$title) : base($key, $title) {
        $this._InitializeComponents()
    }

    # === Constructor (with container) ===
    TabbedScreen([string]$key, [string]$title, [object]$container) : base($key, $title, $container) {
        $this._InitializeComponents()
    }

    # === Initialization ===

    hidden [void] _InitializeComponents() {
        # Get terminal size
        $termSize = $this._GetTerminalSize()
        $this.TermWidth = $termSize.Width
        $this.TermHeight = $termSize.Height

        # Initialize TabPanel
        $this.TabPanel = [TabPanel]::new()

        # Position and size TabPanel to fit in content area
        # Account for header (3 rows), footer (2 rows), menu (1 row)
        $contentHeight = $this.TermHeight - 6

        $this.TabPanel.X = 2
        $this.TabPanel.Y = 4  # Below header
        $this.TabPanel.Width = $this.TermWidth - 4
        $this.TabPanel.Height = $contentHeight

        # Wire up TabPanel events
        $self = $this
        $this.TabPanel.OnTabChanged = {
            param($tabIndex)
            $self.OnTabChanged($tabIndex)
        }.GetNewClosure()

        $this.TabPanel.OnFieldSelected = {
            param($field)
            $self.OnFieldSelected($field)
        }.GetNewClosure()

        # Initialize InlineEditor (for editing fields)
        $this.InlineEditor = [InlineEditor]::new()
        $this.InlineEditor.LayoutMode = "vertical"  # Popup mode
        $this.InlineEditor.X = 10
        $this.InlineEditor.Y = 8
        $this.InlineEditor.Width = 60
        $this.InlineEditor.Height = 12

        # Wire up InlineEditor events
        $this.InlineEditor.OnConfirmed = {
            param($values)
            $self._SaveEditedField($values)
        }.GetNewClosure()

        $this.InlineEditor.OnCancelled = {
            $self.ShowEditor = $false
            $self.CurrentEditField = $null
        }.GetNewClosure()

        # Configure footer shortcuts
        $this.Footer.ClearShortcuts()
        $this.Footer.AddShortcut("Tab", "Next Tab")
        $this.Footer.AddShortcut("↑↓", "Navigate")
        $this.Footer.AddShortcut("Enter", "Edit")
        $this.Footer.AddShortcut("S", "Save")
        $this.Footer.AddShortcut("Esc", "Back")
    }

    # === Lifecycle Methods ===

    [void] OnEnter() {
        $this.IsActive = $true

        # Load data
        $this.LoadData()

        # Update header breadcrumb
        if ($this.Header) {
            $this.Header.SetBreadcrumb(@("Home", $this.ScreenTitle))
        }
    }

    [void] OnExit() {
        $this.IsActive = $false
    }

    # === Abstract Methods (MUST override) ===

    <#
    .SYNOPSIS
    Load data and populate tabs (ABSTRACT - must override)
    #>
    [void] LoadData() {
        throw "LoadData() must be implemented in subclass"
    }

    <#
    .SYNOPSIS
    Save changes from all field values (ABSTRACT - must override)
    #>
    [void] SaveChanges() {
        throw "SaveChanges() must be implemented in subclass"
    }

    # === Optional Override Methods ===

    <#
    .SYNOPSIS
    Handle tab change (optional override)
    #>
    [void] OnTabChanged([int]$tabIndex) {
        # Default: update status bar
        if ($this.StatusBar) {
            $tab = $this.TabPanel.GetCurrentTab()
            if ($tab) {
                $this.StatusBar.SetLeftText("Tab: $($tab.Name) ($($tab.Fields.Count) fields)")
            }
        }
    }

    <#
    .SYNOPSIS
    Handle field selection (optional override)
    #>
    [void] OnFieldSelected($field) {
        # Default: update status bar
        if ($this.StatusBar -and $field) {
            $value = if ($field.Value) { $field.Value } else { "(empty)" }
            $this.StatusBar.SetLeftText("$($field.Label): $value")
        }
    }

    <#
    .SYNOPSIS
    Handle field edit (optional override)
    #>
    [void] OnFieldEdited($field, $newValue) {
        # Default: just update the field
        # Subclass can override to add validation, logging, etc.
    }

    # === Field Editing ===

    [void] EditCurrentField() {
        $field = $this.TabPanel.GetCurrentField()
        if ($null -eq $field) { return }

        $this.CurrentEditField = $field

        # Build field definition for InlineEditor
        $fieldType = if ($field.ContainsKey('Type')) { $field.Type } else { 'text' }
        $fieldDef = @{
            Name = $field.Name
            Label = $field.Label
            Type = $fieldType
            Value = $field.Value
            Required = if ($field.ContainsKey('Required')) { $field.Required } else { $false }
        }

        # Add type-specific properties
        if ($fieldType -eq 'number') {
            if ($field.ContainsKey('Min')) { $fieldDef.Min = $field.Min }
            if ($field.ContainsKey('Max')) { $fieldDef.Max = $field.Max }
        }

        $this.InlineEditor.SetFields(@($fieldDef))
        $this.InlineEditor.Title = "Edit $($field.Label)"
        $this.ShowEditor = $true
    }

    hidden [void] _SaveEditedField($values) {
        if ($null -eq $this.CurrentEditField) { return }

        $fieldName = $this.CurrentEditField.Name
        $newValue = $values[$fieldName]

        # Update TabPanel field value
        $this.TabPanel.UpdateFieldValue($fieldName, $newValue)

        # Call subclass hook
        $this.OnFieldEdited($this.CurrentEditField, $newValue)

        # Close editor
        $this.ShowEditor = $false
        $this.CurrentEditField = $null

        # Show success message
        if ($this.StatusBar) {
            $this.StatusBar.SetRightText("Field updated")
        }
    }

    # === Input Handling ===

    [bool] HandleKeyPress([ConsoleKeyInfo]$keyInfo) {
        # If editor is showing, route to it first
        if ($this.ShowEditor) {
            $handled = $this.InlineEditor.HandleInput($keyInfo)

            # Check if editor closed
            if ($this.InlineEditor.IsConfirmed -or $this.InlineEditor.IsCancelled) {
                $this.ShowEditor = $false
                $this.CurrentEditField = $null
                return $true
            }

            if ($handled) {
                return $true
            }
        }

        # Enter key - edit current field
        if ($keyInfo.Key -eq 'Enter') {
            $this.EditCurrentField()
            return $true
        }

        # S key - save all changes
        if ($keyInfo.KeyChar -eq 's' -or $keyInfo.KeyChar -eq 'S') {
            try {
                $this.SaveChanges()
                if ($this.StatusBar) {
                    $this.StatusBar.SetRightText("Changes saved")
                }
            } catch {
                if ($this.StatusBar) {
                    $this.StatusBar.SetRightText("Save failed: $_")
                }
            }
            return $true
        }

        # Escape - go back
        if ($keyInfo.Key -eq 'Escape') {
            $this.App.PopScreen()
            return $true
        }

        # Route to TabPanel
        return $this.TabPanel.HandleInput($keyInfo)
    }

    # === Rendering ===

    [string] RenderContent() {
        if (-not $this.TabPanel) {
            return ""
        }

        # Render TabPanel
        $output = $this.TabPanel.Render()

        # If editor is showing, render it on top
        if ($this.ShowEditor -and $this.InlineEditor) {
            $output += "`n" + $this.InlineEditor.Render()
        }

        return $output
    }

    # === Helper Methods ===

    hidden [hashtable] _GetTerminalSize() {
        try {
            $width = [Console]::WindowWidth
            $height = [Console]::WindowHeight
            return @{ Width = $width; Height = $height }
        }
        catch {
            return @{ Width = 120; Height = 40 }
        }
    }
}

# Export
Export-ModuleMember -Variable @()
